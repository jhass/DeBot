require "./event"

module Framework
  module Filter
    module Filter
      abstract def call(event : Event) #: Bool
    end

    class NickFilter
      include Filter

      def initialize @config
      end

      def call event
        return false unless event.sender?

        @config.ignores.includes? event.sender.nick
      end
    end

    alias Proc = Event -> Bool
    alias Item = Filter|Proc
  end
end
