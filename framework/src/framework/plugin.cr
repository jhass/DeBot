require "core_ext/string"

require "./channel"
require "./user"
require "./timer"

module Framework
  module Plugin
    macro included

      @@matchers = [] of Regex
      def self.matchers
        @@matchers
      end

      @@events = [] of Symbol
      def self.events
        @@events
      end
    end

    macro match regex : Regex
      matchers << {{regex}}
    end

    macro listen event
      events << {{event}}
    end

    property! context
    # property container

    def self.validate
      raise PluginError.new("No matcher defined for #{self.class}!") unless @@matchers
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
  end
end
