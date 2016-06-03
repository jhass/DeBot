require "logger"
require "json"

require "irc/connection"

module Framework
  class Configuration
    class Error < Exception
    end

    module Plugin
      class ChannelList
        def self.new(pull : JSON::PullParser)
          case pull.kind
          when :null
            default
          when :begin_array
            new Array(String).new pull
          when :bool
            if pull.read_bool == false
              none
            else
              raise Error.new "true is not a valid value for the channel list"
            end
          else
            raise Error.new "invalid channel list (#{pull.kind}"
          end
        end

        def self.default
          new true
        end

        def self.none
          new false
        end

        @channels : Array(String)

        def initialize(channels : Array(String)|Bool)
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

        def wants?(event : Event)
          if event.type == :message && event.message.channel?
            wants? event.message
          else
            true
          end
        end

        def wants?(message : Message)
          listens_to? message.channel
        end

        def listens_to?(channel)
          return false unless @wants_channel_messsages
          return true if @channels.empty?

          @channels.includes? channel.name
        end

        def add(channel : Channel)
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

        def remove(channel : Channel)
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

        def to_json(io)
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

      property! name : String
      delegate listens_to?, channels!
      delegate wants?, channels!

      def channels!
        @channels ||= ChannelList.default
      end

      def save(config)
        config.update_plugin_config name, JSON.parse(to_json)
      end
    end

    class Store
      JSON.mapping({
        server:          {type: String},
        port:            {type: Int32,                   nilable: true},
        channels:        {type: Array(String)},
        nick:            {type: String},
        user:            {type: String,                  nilable: true},
        password:        {type: String,                  nilable: true, emit_null: true},
        nickserv_regain: {type: Bool,                    nilable: true},
        realname:        {type: String,                  nilable: true},
        ssl:             {type: Bool,                    nilable: true},
        try_sasl:        {type: Bool,                    nilable: true},
        log_level:       {type: String,                  nilable: true},
        ignores:         {type: Array(String),           nilable: true},
        plugins:         {type: Hash(String, JSON::Any), nilable: true}
      }, true)

      def self.load_plugins(config, json)
        pull = JSON::PullParser.new json
        pull.on_key("plugins") do
          pull.read_object do |key|
            config.plugins[key].read_config(pull)
          end
        end
      end

      def plugins
        plugins = @plugins

        unless plugins.is_a? Hash(String, JSON::Any)
          plugins = Hash(String, JSON::Any).new
          @plugins = plugins
        end

        plugins
      end

      def plugins=(value : JSON::Any)
        @plugins = value
      end

      def to_json(config : Configuration)
        self.port            = config.port
        self.channels        = config.channels
        self.user            = config.user
        self.password        = config.password
        self.nickserv_regain = config.nickserv_regain?
        self.realname        = config.realname
        self.ssl             = config.ssl?
        self.try_sasl        = config.try_sasl?
        self.log_level       = config.log_level
        self.ignores         = config.ignores

        to_pretty_json
      end

      def restore(config)
        config.server          = server
        config.port            = port            unless port.nil?
        config.channels        = channels
        config.nick            = nick
        config.user            = user            unless user.nil?
        config.password        = password        unless password.nil?
        config.nickserv_regain = nickserv_regain unless nickserv_regain.nil?
        config.realname        = realname        unless realname.nil?
        config.ssl             = ssl             unless ssl.nil?
        config.try_sasl        = try_sasl        unless try_sasl.nil?
        config.log_level       = log_level       unless log_level.nil?
        config.ignores         = ignores         unless ignores.nil?
      end
    end

    LOG_LEVELS = {
      "debug" => Logger::Severity::DEBUG,
      "info"  => Logger::Severity::INFO,
      "warn"  => Logger::Severity::WARN,
      "error" => Logger::Severity::ERROR,
      "fatal" => Logger::Severity::FATAL
    }

    property! server : String?
    property  port : Int32?
    property  channels
    property! nick
    property! user : String?
    property  password : String?
    property? nickserv_regain : Bool?
    property! realname : String?
    property? ssl : Bool?
    property? try_sasl : Bool?
    property  log_level : String?
    property! ignores : Array(String)?
    getter    logger
    getter    plugins

    @config_file : String?
    @store : Store?

    def initialize
      @plugins  = Hash(String, PluginContainer::Workaround).new
      @channels = [] of String
      @logger   = Logger.new(STDOUT)

      @nick            = "CeBot"
      @user            = "cebot"
      @password        = nil
      @nickserv_regain = false
      @realname        = "CeBot"
      @ssl             = false
      @try_sasl        = false
      @log_level       = "info"
      @ignores         = [] of String

      set_log_level
    end

    def port
      @port || (@ssl ? 6697 : 6667)
    end

    def add_plugin(plugin : PluginContainer)
      plugins[plugin.name] = plugin
    end

    def from_file(path)
      @config_file = path
    end

    def update_plugin_config(plugin, config)
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

    def load
      json = read_config
      store = Store.from_json(json)
      store.restore(self)
      @store = store
      Store.load_plugins self, json
      set_log_level
    end

    def reload
      load
    end

    def to_connection
      load if @config_file

      IRC::Connection.build do |config|
        config.server   = server
        config.port     = port
        config.nick     = nick
        config.user     = user
        config.password = password
        config.realname = realname
        config.ssl      = ssl?
        config.try_sasl = try_sasl?
        config.logger   = logger
      end
    end

    private def read_config
      path = @config_file
      raise Error.new("No configuration file defined") unless path
      File.read_lines(path).reject(&.match(/^\s*\/\//)).join
    end

    private def set_log_level
      raise Error.new("Unknown log level #{log_level}") unless LOG_LEVELS.has_key? log_level

      logger.level = LOG_LEVELS[log_level]
    end
  end
end
