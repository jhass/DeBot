require "thread/synchronized"

require "./message"

module IRC
  class Channel
    getter name
    getter users

    def initialize @connection, @name
      @message_handlers = [] of Message ->
      @userlist_handlers = [] of Array(String)|String ->
      @users = Synchronized.new([] of String)


      @connection.on Message::PRIVMSG, Message::NOTICE do |message|
        target = message.parameters.first
        @message_handlers.each &.call(message) if target == @name
      end

      @connection.on(IRC::Message::RPL_NAMREPLY) do |reply|
        channel = reply.parameters[2]
        if channel == @name
          @users.concat reply.parameters.last.split(' ')
        end
      end

      @connection.on(IRC::Message::RPL_ENDOFNAMES) do |reply|
        if reply.parameters[1] == @name
          @users.uniq!
          @userlist_handlers.each &.call(@users.dup)
        end
      end

      @connection.on(IRC::Message::MODE) do |message|
        if message.parameters.first == @name
          mode = message.parameters[1]

          flags = mode.chars
          add = flags.shift == '+'

          flags.each_with_index do |flag, i|
            nick = message.parameters[i+2]

            index = @users.index(nick) || @users.index("@#{nick}") || @users.index("+#{nick}")
            olduser = index ? @users[index] : ""

            if add
              case flag
              when 'o'
                newuser = "@#{nick}"
              when 'v'
                newuser = olduser.starts_with?('@') ? olduser : "+#{nick}"
              else
                newuser = olduser
              end
            else # "-o", "-v"
              newuser = nick
            end

            if newuser != olduser
              if index
                @users[index] = newuser
              else
                @users << newuser
              end

              @userlist_handlers.each &.call(newuser)
            end
          end
        end
      end
    end

    def on_message(&block : Message ->)
      @message_handlers << block
    end

    def on_userlist_update(&block : Array(String)|String ->)
      @userlist_handlers << block
    end

    def join
      @connection.send "JOIN #{@name}"
    end

    def part
      @connection.send "PART #{@name}"
    end
  end
end
