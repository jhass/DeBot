require "core_ext/string"

require "./channel"
require "./user"

module Framework
  module Plugin
    macro match regex : Regex
      @@matchers ||= [] of Regex
      @@matchers.not_nil! << {{regex}}
    end

    getter! context

    def handle_message message
      @context = message.context

      @@matchers.not_nil!.each do |regex|
        match = message.message.match regex
        if match
          begin
            execute message, match
          rescue e
            puts "Couldn't run plugin #{self} for #{message} matched by #{regex}:"
            puts e
            puts e.backtrace.join("\n")
          end
          break
        end
      end
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
  end

  class PluginError < Exception
  end
end
