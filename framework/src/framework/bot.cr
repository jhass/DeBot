require "signal"

require "thread/synchronized"
require "irc/connection"
require "irc/message"

require "./configuration"
require "./event"
require "./filter"
require "./message"
require "./channel"
require "./plugin_container"
require "./plugin"

module Framework
  class Bot
    getter    config
    getter!   connection
    property! user
    delegate  channels, config
    delegate  logger,   config

    def self.create
      new.tap do |bot|
        with bot yield
      end
    end

    private def initialize
      @config  = Configuration.new
      @filters = [] of Filter::Item
      @started = false

      add_filter Filter::NickFilter.new(config)
    end

    macro add_plugin klass
      config.add_plugin Framework::PluginContainer({{klass}}).new
    end

    def add_filter filter : Filter::Item
      @filters << filter
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
        event   = Event.new(self, :message, message)
        config.plugins.each_value &.handle(event)
      end

      Channel.from_name(name, self)
    end

    def part name
      connection.part name if config.channels.includes? name
      config.channels.delete name
      config.save
    end

    def start
      connection = config.to_connection
      @connection = connection
      @user = User.from_nick config.nick, self
      user.mask.user = config.user

      connection.on_query do |message|
        event = Event.new self, :message, Message.new(self, message)
        config.plugins.each_value &.handle(event)
      end

      connection.on(IRC::Message::NICK) do |message|
        if prefix = message.prefix
          event = Event.new self, :nick, user
          config.plugins.each_value &.handle(event)
        end
      end

      connection.on(IRC::Message::ERR_NICKCOLLISION, IRC::Message::ERR_NICKNAMEINUSE) do |message|
        if config.nickserv_regain? && config.password
          connection.await IRC::Message::RPL_WELCOME
          connection.send IRC::Message::PRIVMSG, "NickServ", "REGAIN #{config.nick} #{config.password}"
        end
      end

      connection.on(IRC::Message::KICK) do |message|
        channel, nick = message.parameters
        part channel if nick == user.nick
      end

      connection.connect

      channels.each do |channel|
        join channel
      end

      @started = true

      Signal::HUP.trap do
        config.reload
      end

      connection.on(IRC::Message::JOIN, IRC::Message::PART) do |message|
        if prefix = message.prefix
          type = message.type == IRC::Message::JOIN ? :join : :part
          channel = message.parameters.first
          user = User.from_mask(prefix, self)
          event = Event.new self, type, user, Channel.from_name(channel, self)
          config.plugins.each_value &.handle(event)

          part channel if message.type == IRC::Message::PART && user.nick == self.user.nick
        end
      end

      event = Event.new self, :connected
      config.plugins.each_value &.handle(event)

      connection.block
    end

    def filter? event
      @filters.any? &.call(event)
    end
  end
end
