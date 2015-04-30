require "logger"
require "json"

require "irc/connection"

module Framework
  class Configuration
    module Plugin
      class ChannelList
        def self.new pull : JSON::PullParser
          case pull.kind
          when :null
            default
          when :begin_array
            new Array(String).new pull
          when :bool
            if pull.read_bool == false
              none
            else
              raise ArgumentError.new "true is not a valid value for the channel list"
            end
          else
            raise ArgumentError.new "invalid channel list (#{pull.kind}"
          end
        end

        def self.default
          new true
        end

        def self.none
          new false
        end

        def initialize channels : Array(String)|Bool
          case channels
          when Bool
            @wants_channel_messsages = channels
            @channels = [] of String
          when Array(String)
            @wants_channel_messsages = !channels.empty?
            @channels = channels
          else
            raise "bug" # prevent nilable
          end
        end

        def wants? message
          listens_to? message.channel
        end

        def listens_to? channel
          return false unless @wants_channel_messsages
          return true if @channels.empty?

          @channels.includes? channel.name
        end

        def add channel : Channel
          if @wants_channel_messsages
            unless @channels.empty? || @channels.includes?(channel.name)
              @channels << channel.name
            end
          else
            @wants_channel_messsages = true

            unless @channels.includes? channel.name
              @channels << channel.name
            end
          end
        end

        def remove channel : Channel
          if @channels.includes? channel.name
            @channels.delete channel.name
            if @channels.empty?
              @wants_channel_messsages = false
            end
          elsif @channels.empty? && @wants_channel_messsages
            @channels = channel.context.channels.dup
            @channels.delete channel.name
          end
        end

        def to_json io
          value = if @wants_channel_messsages
            if @channels.empty?
              nil
            else
              @channels
            end
          else
            false
          end

          value.to_json io
        end
      end

      macro included
        def self.empty
          obj = allocate
          obj.initialize_empty
          obj
        end
      end

      class Default
        include Plugin

        json_mapping({
          channels: {type: Framework::Configuration::Plugin::ChannelList, nilable: true, emit_null: true}
        })

        def initialize_empty
          @channels = ChannelList.default
        end
      end

      property! name
      delegate listens_to?, channels!
      delegate wants?,      channels!

      def channels!
        @channels ||= ChannelList.default
      end

      def save(config)
        config.update_plugin_config name, JSON.parse(to_json)
      end
    end

    class Store
      json_mapping({
        server:    {type: String},
        port:      {type: Int32,     nilable: true},
        channels:  {type: Array(String)},
        nick:      {type: String},
        user:      {type: String,    nilable: true},
        password:  {type: String,    nilable: true, emit_null: true},
        realname:  {type: String,    nilable: true},
        ssl:       {type: Bool,      nilable: true},
        try_sasl:  {type: Bool,      nilable: true},
        log_level: {type: String,    nilable: true},
        plugins:   {type: JSON::Any, nilable: true}
      }, true)

      def self.load_plugins config, json
        pull = JSON::PullParser.new json
        pull.on_key("plugins") do
          pull.read_object do |key|
            config.plugins[key].read_config(pull)
          end
        end
      end

      def plugins
        plugins = @plugins

        unless plugins.is_a? Hash(String, JSON::Type)
          plugins = Hash(String, JSON::Type).new
          @plugins = plugins
        end

        plugins
      end

      def plugins= value : JSON::Value
        @plugins = value
      end

      def to_json config : Configuration
        self.port      = config.port
        self.channels  = config.channels
        self.user      = config.user
        self.password  = config.password
        self.realname  = config.realname
        self.ssl       = config.ssl
        self.try_sasl  = config.try_sasl
        self.log_level = config.log_level

        to_pretty_json
      end

      def restore config
        config.server    = server
        config.port      = port      unless port.nil?
        config.channels  = channels
        config.nick      = nick
        config.user      = user      unless user.nil?
        config.password  = password  unless password.nil?
        config.realname  = realname  unless realname.nil?
        config.ssl       = ssl       unless ssl.nil?
        config.try_sasl  = try_sasl  unless try_sasl.nil?
        config.log_level = log_level unless log_level.nil?
      end
    end

    LOG_LEVELS = {
      "debug" => Logger::Severity::DEBUG,
      "info"  => Logger::Severity::INFO,
      "warn"  => Logger::Severity::WARN,
      "error" => Logger::Severity::ERROR,
      "fatal" => Logger::Severity::FATAL
    }

    property! server
    property  port
    property  channels
    property! nick
    property! user
    property  password
    property! realname
    property  ssl
    property  try_sasl
    property  log_level
    getter    logger
    getter    plugins

    def initialize
      @plugins  = Hash(String, PluginContainer).new
      @channels = [] of String
      @logger   = Logger.new(STDOUT)

      @nick      = "CeBot"
      @user      = "cebot"
      @password  = nil
      @realname  = "CeBot"
      @ssl       = false
      @try_sasl  = false
      @log_level = "info"

      set_log_level
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

    def reload
      json = read_config

      set_log_level

      Store.load_plugins self, json

      store = @store
      if store
        pull = JSON::PullParser.new json
        pull.on_key("plugins") do
          store.plugins = JSON::Any.new(pull)
        end
      end
    end

    def update_plugin_config plugin, config
      store = @store
      path = @config_file
      return unless store && path

      store.plugins[plugin] = config
      save
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
        set_log_level
      end

      IRC::Connection.build do |config|
        config.server   = server
        config.port     = port
        config.nick     = nick
        config.user     = user
        config.password = password
        config.realname = realname
        config.ssl      = ssl
        config.try_sasl = try_sasl
        config.logger   = logger
      end
    end

    private def read_config
      path = @config_file
      raise "No configuration file defined" unless path
      File.read_lines(path).reject(&.match(/^\s*\/\//)).join
    end

    private def set_log_level
      raise "Unknown log level #{log_level}" unless LOG_LEVELS.has_key? log_level

      logger.level = LOG_LEVELS[log_level]
    end
  end
end
