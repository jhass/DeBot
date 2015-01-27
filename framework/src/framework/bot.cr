require "thread/synchronized"
require "irc/connection"

require "./message"
require "./plugin"

module Framework
  class Bot
    getter! connection
    getter channels
    property! user

    class Configuration
      property! server
      property  port
      property  channels
      property  user
      property! nick
      property  realname
      getter    plugins

      def initialize
        @plugins = [] of {Plugin, Array(String)}
        @port = 6667
        @channels = Tuple.new
        @user = "cebot"
        @nickname = "CeBot"
        @realname = "CeBot"
      end

      def add_plugin plugin : Plugin, channel_whitelist = [] of String
        plugins << {plugin as Plugin, channel_whitelist}
      end
    end

    def self.create
      new.tap do |bot|
        yield bot.config
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
        config.plugins.each do |item|
          plugin, channel_whitelist = item
          if channel_whitelist.empty? || (message.channel? && channel_whitelist.includes?(message.channel.name))
            plugin.handle_message(message)
          end
        end
      end
    end

    def part name
      connection.part name if channels.includes? name
      channels.delete name
    end

    def start
      connection = IRC::Connection.new config.server, config.port, config.nick, config.user
      @connection = connection

      connection.on_query do |message|
        message = Message.new self, message
        config.plugins.each &.[0].handle_message(message)
      end

      connection.on(IRC::Message::NICK) do |message|
        if prefix = message.prefix
          User.from_mask(prefix, self).nick = message.parameters.first
        end
      end

      connection.on(IRC::Message::RPL_NAMREPLY) do |reply|
        # TODO: we get away status for free here, track it
        nicks = reply.parameters.last.split(' ').map {|nick|
          nick.starts_with?('@') || nick.starts_with?('+') ? nick[1..-1] : nick
        }

        # TODO: update channel user list
      end

      connection.on(IRC::Message::RPL_WHOISUSER) do |reply|
        nick, user, host, _unused, realname = reply.parameters
        user = User.from_nick(nick, self)
        user.mask.user = user
        user.mask.host = host
        user.realname = realname
      end

      connection.connect
      config.nick = connection.nick

      config.channels.each do |channel|
        join channel
      end

      connection.block
    end
  end
end
