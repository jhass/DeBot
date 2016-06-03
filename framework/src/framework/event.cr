require "./bot"
require "./message"
require "./user"
require "./channel"

module Framework
  class Event
    getter context
    getter type
    getter! sender : User
    getter! channel : Channel
    getter! message : Message

    def initialize(@context : Bot, @type : Symbol, @message : Message)
      @sender = message.sender
      @channel = message.channel?
    end

    def initialize(@context : Bot, @type : Symbol, @sender : User)
    end

    def initialize(@context : Bot, @type : Symbol, @sender : User, @channel : Channel)
    end

    def initialize(@context : Bot, @type : Symbol)
    end
  end
end
