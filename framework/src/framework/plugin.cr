require "core_ext/string"

module Framework
  module Plugin
    # macro match string : String

    # end

    macro match regex : Regex
      @@matchers ||= [] of Regex
      @@matchers.not_nil! << {{regex}}
    end

    def handle_message message
      @@matchers.not_nil!.each do |regex|
        match = message.content.match regex
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
      raise PluginError, "No matcher defined for #{self.class}!" unless @@matchers
    end
  end

  class PluginError < Exception
  end
end
