require "./bot"
require "./message"
require "./user"
require "./channel"

module Framework
  struct Event
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

    def to_s(io)
      io << "<Event: " << self.type
      io << " From: " << sender.nick if sender?
      io << " To: " << channel.name if channel?
      io << " Message: " << message if message?
      io << '>'
    end
  end
end
