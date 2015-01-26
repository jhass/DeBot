require "./message"

module IRC
  class Channel
    getter name

    def initialize @connection, @name
      @handlers = [] of (Message) ->

      @connection.on Message::PRIVMSG, Message::NOTICE do |message|
        target = message.parameters.first
        @handlers.each &.call(message) if target == @name
      end
    end

    def on_message(&block : (Message) ->)
      @handlers << block
    end

    def join
      @connection.send "JOIN #{@name}"
    end

    def part
      @connection.send "PART #{@name}"
      @handlers.clear
    end
  end
end
