require "core_ext/string"

require "./configuration"
require "./channel"
require "./user"
require "./timer"

module Framework
  module Plugin
    macro config properties
      {% for key, value in properties %}
        {% properties[key] = {type: value} unless value.is_a?(HashLiteral) %}
      {% end %}

      class Config
        include Framework::Configuration::Plugin

        JSON.mapping({
          :channels => {type: Framework::Configuration::Plugin::ChannelList, nilable: true, emit_null: true},
          {% for key, value in properties %}
            {{key}} => {{value}},
          {% end %}
        }, true)

        def initialize_empty
          @channels = nil
          {% for key, value in properties %}
            @{{key.id}} = {{value[:default]}}
          {% end %}
        end
      end

      def self.config_class
        Config
      end
    end

    macro included
      def self.config_class
        Framework::Configuration::Plugin::Default
      end

      @@matchers = [] of Regex
      def self.matchers
        @@matchers
      end

      @@events = [] of Symbol
      def self.events
        @@events
      end

      def self.config_loaded config
      end
    end

    macro match regex
      matchers << {{regex}}
    end

    macro listen event
      events << {{event}}
    end

    getter context
    getter config

    def initialize @context, @config
    end

    def channel name
      Channel.from_name name, context
    end

    def user name
      User.from_nick name, context
    end

    def in seconds, &block
      Timer.new seconds, 1, &block
    end

    def every seconds, limit=nil, &block
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
