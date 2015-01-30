require "json"

require "irc/connection"

module Framework
  class Configuration
    class Plugin
      def initialize pull : JSON::PullParser
        pull.on_key("channels") do
          @channels = Array(String).new pull
        end
      end

      def channels!
        @channels ||= [] of String
      end

      def wants? message
        return true if channels!.empty?
        return true unless message.channel?

        channels!.includes? message.channel.name
      end

      def self.none
        @@none ||= None.new
      end
    end

    class Store
      json_mapping({
        server:   {type: String},
        port:     {type: Int32,     nilable: true},
        channels: {type: Array(String)},
        nick:     {type: String},
        user:     {type: String,    nilable: true},
        password: {type: String,    nilable: true, emit_null: true},
        realname: {type: String,    nilable: true},
        ssl:      {type: Bool,      nilable: true},
        try_sasl: {type: Bool,      nilable: true},
        plugins:  {type: JSON::Any, nilable: true}
      }, true)

      def self.load_plugins config, json
        pull = JSON::PullParser.new json
        pull.on_key("plugins") do
          pull.read_object do |key|
            config.plugins[key].read_config(pull)
          end
        end
      end

      def to_json config : Configuration
        self.port     = config.port
        self.channels = config.channels
        self.user     = config.user
        self.password = config.password
        self.realname = config.realname
        self.ssl      = config.ssl
        self.try_sasl = config.try_sasl

        to_json
      end

      def restore config
        config.server   = server
        config.port     = port      unless port.nil?
        config.channels = channels
        config.nick     = nick
        config.user     = user      unless user.nil?
        config.password = password  unless password.nil?
        config.realname = realname  unless realname.nil?
        config.ssl      = ssl       unless ssl.nil?
        config.try_sasl = try_sasl  unless try_sasl.nil?
      end
    end

    property! server
    property  port
    property  channels
    property! nick
    property! user
    property  password
    property! realname
    property  ssl
    property  try_sasl
    getter    plugins

    def initialize
      @plugins = Hash(String, PluginContainer).new
      @channels = [] of String

      @nick = "CeBot"
      @user = "cebot"
      @password = nil
      @realname = "CeBot"
      @ssl = false
      @try_sasl = false
    end

    def port
      @port || (@ssl ? 6697 : 6667)
    end

    def add_plugin plugin : PluginContainer
      plugins[plugin.name] = plugin
    end

    def from_file path
      @config_file = path
    end

    def reload_plugins
      Store.load_plugins self, read_config
    end

    def save
      store = @store
      path = @config_file
      return unless store && path

      json = store.to_json self
      File.write(path, json)
    end

    def to_connection
      if @config_file
        json = read_config
        store = Store.from_json(json)
        store.restore(self)
        @store = store
        Store.load_plugins self, json
      end

      IRC::Connection.build do |config|
        config.server = server
        config.port = port
        config.nick = nick
        config.user = user
        config.password = password
        config.realname = realname
        config.ssl = ssl
        config.try_sasl = try_sasl
      end
    end

    private def read_config
      path = @config_file
      raise "No configuration file defined" unless path
      File.read_lines(path).reject(&.match(/^\s*\/\//)).join
    end
  end
end
