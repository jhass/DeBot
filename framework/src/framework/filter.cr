require "./event"

module Framework
  module Filter
    module Filter
      abstract def call(event : Event) #: Bool
    end

    struct NickFilter
      include Filter

      def initialize(@config : Configuration)
      end

      def call(event)
        return false unless event.sender?

        @config.ignores.includes? event.sender.nick
      end
    end

    alias Proc = Event -> Bool
    alias Item = Filter|Proc
  end
end
