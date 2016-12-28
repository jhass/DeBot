require "irc/message"
require "./user"
require "./channel"
require "./bot"

module Framework
  class Message
    VALID_TYPES = %w(PRIVMSG NOTICE)

    getter target
    getter message
    getter sender : User
    getter context

    @channel : Channel?

    def initialize(@context : Bot, @target : String, @message : String, @type : Symbol|String = "PRIVMSG")
      @type = @type.to_s.upcase
      unless VALID_TYPES.includes? @type
        raise ArgumentError.new("Only valid types are #{VALID_TYPES.join(", ")}")
      end

      @sender = context.user
    end

    def initialize(@context : Bot, message = IRC::Message)
      @target, @message = message.parameters
      prefix = message.prefix
      if prefix
        @sender = User.from_mask(prefix, @context)
      else
        @sender = @context.user
      end
      @type = message.type
      @type = "PRIVMSG" unless VALID_TYPES.includes? @type
    end

    def as_action
      Message.new(@context, @target, "\001ACTION #{@message}\001")
    end

    def reply(text)
      target =  @target.starts_with?('#') ? @target : @sender.nick
      Message.new(@context, target, text, @type).send
    end

    def send
      userhost = @context.user.mask.to_s
      nick = @context.user.nick
      prefix = "#{@type} #{@target} :"
      # 512 max message length according RFC, but Freenode only allows 510
      # -3 for :, ! and space
      # userhost fallback: hostname(63)+nickname(9)+@(1) = 73
      limit = 510 - 3 - nick.size - prefix.size - (userhost ? userhost.size : 73)

      @message.lines.each do |line|
        sent = 0
        while sent < line.size
          @context.connection.send "#{prefix}#{line[sent, limit]}"
          sent += limit
        end
      end
    end

    def channel?
      @channel ||= Channel.from_name(@target, @context) if @target.starts_with? '#'
    end

    def channel
      channel?.not_nil!
    end

    def to_s(io)
      io << "<Message From: " << sender.nick << " To: " << target << " Text: " << message << '>'
    end
  end
end
