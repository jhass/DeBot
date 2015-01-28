require "thread/synchronized"
require "irc/connection"
require "irc/message"

require "./event"
require "./message"
require "./channel"
require "./plugin_container"

module Framework
  class Bot
    macro add_plugin klass, whitelist=nil, arguments=[] of Void
      config.add_plugin Framework::PluginContainer.new { {{klass}}.new({{*arguments}}) }, {{whitelist if whitelist}}
    end

    getter! connection
    getter channels
    property! user

    class Configuration
      record PluginDefinition, plugin, channel_whitelist do
        def wants? message : Message
          return true unless message.channel?
          channel_whitelist.empty? || channel_whitelist.includes?(message.channel.name)
        end
      end

      property! server
      property  port
      property  channels
      property  user
      property! nick
      property  realname
      property  ssl
      getter    plugins

      def initialize
        @plugins = [] of PluginDefinition
        @channels = Tuple.new
        @user = "cebot"
        @nickname = "CeBot"
        @realname = "CeBot"
        @ssl = false
      end

      def port
        @port || (@ssl ? 6697 : 6667)
      end

      def add_plugin plugin : PluginContainer, channel_whitelist = [] of String
        plugins << PluginDefinition.new(plugin, channel_whitelist)
      end

      def to_connection
        IRC::Connection.build do |config|
          config.server = server
          config.port = port
          config.nick = nick
          config.user = user
          config.realname = realname
          config.ssl = ssl
        end
      end
    end

    def self.create
      new.tap do |bot|
        with bot yield
        bot.user = User.from_nick bot.config.nick, bot, bot.config.realname
        bot.user.mask.user = bot.config.user
      end
    end

    private def initialize
      @channels = Synchronized.new [] of String
    end

    def config
      @config ||= Configuration.new
    end

    def join name
      return if channels.includes? name

      channel = connection.join name
      channels << name

      channel.on_message do |message|
        message = Message.new self, message
        config.plugins.each do |definition|
          if definition.wants? message
            definition.plugin.handle Event.new(self, :message, message)
          end
        end
      end

      channel.on_userlist_update do |update|
        Channel.from_name(name, self).update_userlist(update)
      end
    end

    def part name
      connection.part name if channels.includes? name
      channels.delete name
    end

    def start
      connection = config.to_connection
      @connection = connection

      connection.on_query do |message|
        event = Event.new self, :message, Message.new(self, message)
        config.plugins.each &.plugin.handle(event)
      end

      connection.on(IRC::Message::NICK) do |message|
        if prefix = message.prefix
          user = User.from_mask(prefix, self)
          user.nick = message.parameters.first
          event = Event.new self, :nick, user
          config.plugins.each &.plugin.handle(event)
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

      config.channels.each do |channel|
        join channel
      end

      connection.on(IRC::Message::JOIN, IRC::Message::PART) do |message|
        if prefix = message.prefix
          type = message.type == IRC::Message::JOIN ? :join : :part
          channel = message.parameters.first
          event = Event.new self, type, User.from_mask(prefix, self), Channel.from_name(channel, self)
          config.plugins.each &.plugin.handle(event)
        end
      end

      connection.block
    end
  end
end
