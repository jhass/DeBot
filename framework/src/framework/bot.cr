require "thread/synchronized"
require "irc/connection"

require "./message"
require "./plugin"

module Framework
  class Bot
    getter! connection
    getter channels

    class Configuration
      property! :server
      property :port
      property :channels
      property :user
      property :nick
      getter :plugins

      def initialize
        @plugins = [] of {Plugin, Array(String)}
        @port = 6667
        @channels = Tuple.new
        @user = "cebot"
        @nickname = "CeBot"
      end

      def add_plugin plugin : Plugin, channel_whitelist = [] of String
        plugins << {plugin as Plugin, channel_whitelist}
      end
    end

    def self.create
      new.tap do |bot|
        yield bot.config
      end
    end

    def initialize
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
      connection.connect
      config.nick = connection.nick

      connection.on_query do |message|
        message = Message.new self, message
        config.plugins.each &.[0].handle_message(message)
      end

      config.channels.each do |channel|
        join channel
      end

      connection.block
    end
  end
end
