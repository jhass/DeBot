require "signal"

require "thread/synchronized"
require "irc/connection"
require "irc/message"

require "./configuration"
require "./event"
require "./message"
require "./channel"
require "./plugin_container"
require "./plugin"

module Framework
  class Bot
    macro add_plugin klass
      config.add_plugin Framework::PluginContainer({{klass}}).new
    end

    def self.create
      new.tap do |bot|
        with bot yield
        bot.user = User.from_nick bot.config.nick, bot, bot.config.realname
        bot.user.mask.user = bot.config.user
      end
    end

    getter    config
    getter!   connection
    property! user
    delegate  channels, config
    delegate  logger,   config

    private def initialize
      @config  = Configuration.new
      @started = false
    end

    def join name
      return if config.channels.includes?(name) && @started

      channel = connection.join name

      if @started
        config.channels << name
        config.save
      end

      channel.on_message do |message|
        message = Message.new self, message
        config.plugins.each_value do |container|
          if container.wants? message
            container.handle Event.new(self, :message, message)
          end
        end
      end

      Channel.from_name(name, channel, self)
    end

    def part name
      connection.part name if config.channels.includes? name
      config.channels.delete name
      config.save
    end

    def start
      connection = config.to_connection
      @connection = connection

      connection.on_query do |message|
        event = Event.new self, :message, Message.new(self, message)
        config.plugins.each_value &.handle(event)
      end

      connection.on(IRC::Message::NICK) do |message|
        if prefix = message.prefix
          user = User.from_mask(prefix, self)
          user.nick = message.parameters.first
          event = Event.new self, :nick, user
          config.plugins.each_value &.handle(event)
        end
      end

      connection.on(IRC::Message::RPL_WHOISUSER) do |reply|
        nick, user, host, _unused, realname = reply.parameters
        user = User.from_nick(nick, self)
        user.mask.user = user
        user.mask.host = host
        user.realname = realname
      end

      connection.connect
      user.nick = connection.config.nick

      channels.each do |channel|
        join channel
      end

      connection.on(IRC::Message::JOIN, IRC::Message::PART) do |message|
        if prefix = message.prefix
          type = message.type == IRC::Message::JOIN ? :join : :part
          channel = message.parameters.first
          event = Event.new self, type, User.from_mask(prefix, self), Channel.from_name(channel, self)
          config.plugins.each_value &.handle(event)
        end
      end

      Signal.trap(Signal::HUP) do
        config.reload
      end

      @started = true

      connection.block
    end
  end
end
