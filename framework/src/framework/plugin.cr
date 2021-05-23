require "./configuration"
require "./channel"
require "./user"
require "./timer"

module Framework
  module Plugin
    macro config(properties)
      class Config
        {% for key, value in properties %}
          property {{key.id}} : {{value[:type]}}
        {% end %}

        def initialize_empty
          @channels = nil

          {% for key, value in properties %}
            @{{key.id}} = {{value[:default]}}
          {% end %}
        end
      end
    end

    macro included
      class Config
        include Framework::Configuration::Plugin
        include JSON::Serializable
        include JSON::Serializable::Strict

        @[JSON::Field(emit_null: true)]
        property channels : Framework::Configuration::Plugin::ChannelList?

        def initialize_empty
          @channels = ChannelList.default
        end
      end

      def self.config_class
        Config
      end

      @@matchers = [] of Regex
      def self.matchers
        @@matchers
      end

      @@events = [] of Symbol
      def self.events
        @@events
      end

      def self.config_loaded(config)
      end

      def initialize(@context : Framework::Bot, @config : Config)
      end
    end

    def self.config_class
      raise "Workaround issues mentioned in crystal-lang/crystal#2425"
    end

    def self.events
      raise "Workaround issues mentioned in crystal-lang/crystal#2425"
    end

    macro match(regex)
      matchers << {{regex}}
    end

    macro listen(event)
      events << {{event}}
    end

    getter context
    getter config

    def channel(name)
      Channel.from_name name, context
    end

    def user(name)
      User.from_nick name, context
    end

    def after(seconds, &block)
      Timer.new seconds, 1, &block
    end

    def every(seconds, limit=nil, &block)
      Timer.new seconds, limit, &block
    end

    def bot
      context.user
    end

    def logger
      context.logger
    end
  end
end
