require "core_ext/string"

require "./channel"
require "./user"
require "./timer"

module Framework
  module Plugin
    macro match regex : Regex
    @@matchers ||= [] of Regex
      @@matchers.not_nil! << {{regex}}
    end

    macro listen event
      @@events ||= [] of Symbol
      @@events.not_nil! << {{event}}
    end

    property! context
    # property container

    def matchers
      @@matchers.not_nil!
    end

    def events
      @@events.not_nil!
    end

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
