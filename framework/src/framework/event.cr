require "./bot"
require "./message"
require "./user"
require "./channel"

module Framework
  class Event
    getter context
    getter type
    getter sender
    getter! channel
    getter! message

    def initialize @context : Bot, @type : Symbol, @message : Message
      @sender = message.sender
      @channel = message.channel?
    end

    def initialize @context : Bot, @type : Symbol, @sender : User
    end

    def initialize @context : Bot, @type : Symbol, @sender : User, @channel : Channel
    end
  end
end
