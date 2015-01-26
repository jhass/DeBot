require "irc/message"
require "./user"

module Framework
  class Message
    getter target
    getter content
    getter sender
    getter context

    def initialize @context : Bot, message = IRC::Message
      @target, @content = message.parameters
      prefix = message.prefix
      if prefix
        @sender = User.find_or_create_by_mask(prefix)
      else
        @sender = User.none
      end
    end

    def reply text
      userhost = @context.connection.userhost?
      nick = @context.connection.nick
      prefix = "PRIVMSG #{@target} :"
      # 512 max message length according RFC, but Freenode only allows 510
      # -3 for :, ! and space
      # userhost fallback: hostname(63)+nickname(9)+@(1) = 73
      limit = 510 - 3 - nick.size - prefix.size - (userhost ? userhost.size : 73)

      text.lines.each do |line|
        sent = 0
        while sent < line.size
          @context.connection.send "#{prefix}#{line[sent, limit]}"
          sent += limit
        end
      end
    end

    def channel
      @target if @target.starts_with? '#'
    end

    def channel!
      channel.not_nil!
    end
  end
end
