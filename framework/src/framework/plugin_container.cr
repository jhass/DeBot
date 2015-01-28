require "./plugin"

module Framework
  class PluginContainer
    def initialize &@constructor : -> Plugin
    end

    def instance
      @constructor.call
    end

    def handle event
      @context = event.context
      plugin = instance

      handle_message(event.message, plugin) if event.type == :message

      begin
        plugin.react_to(event) if plugin.responds_to?(:react_to) && plugin.events.includes? event.type
      rescue e
        puts "Couldn't run plugin #{self} for #{event}:"
        puts e
        puts e.backtrace.join("\n")
      end
    end

    private def handle_message message, plugin
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
