require "./plugin"

module Framework
  class PluginContainer
    def initialize &@constructor : -> Plugin
    end

    def instance
      @constructor.call
    end

    def handle_message message
      @context = message.context
      # TODO: find a way to add class methods to the base on include and instantiate after match
      plugin = instance

      plugin.matchers.each do |regex|
        match = message.message.match regex
        if match
          begin
            plugin.context = message.context
            # plugin.container = self
            plugin.execute message, match
          rescue e
            puts "Couldn't run plugin #{self} for #{message} matched by #{regex}:"
            puts e
            puts e.backtrace.join("\n")
          end
          break
        end
      end
    end
  end

  class PluginError < Exception
  end
end
