require "thread/synchronized"

require "./message"

module IRC
  class Channel
    record Membership, nick, opped, voiced do
      def_equals_and_hash nick

      def opped?
        opped
      end

      def voiced?
        voiced
      end

      def self.parse membership
        opped = membership[0] == '@'
        voiced = membership[0] == '+'
        nick = opped || voiced ? membership[1..-1] : membership
        new nick, opped, voiced
      end

      def to_s(io)
        io << opped? ? "@" : (voiced? ? "+" : "")
        io << nick
      end
    end

    getter name
    getter users

    def initialize @connection, @name
      @message_handlers = [] of Message ->
      @users = Synchronized.new(Set(Membership).new)


      @connection.on Message::PRIVMSG, Message::NOTICE do |message|
        target = message.parameters.first
        @message_handlers.each &.call(message) if target == @name
      end

      @connection.on(IRC::Message::RPL_NAMREPLY) do |reply|
        channel = reply.parameters[2]
        return unless channel == @name

        reply.parameters.last.split(' ').each do |user|
          create_or_update_membership(user)
        end
      end

      @connection.on(IRC::Message::JOIN, IRC::Message::PART) do |message|
        channel = message.parameters.first
        return unless channel == @name

        if prefix = message.prefix
          nick, _rest = prefix.split('!')
        else
          nick = @connection.config.nick
        end

        if message.type == IRC::Message::JOIN
          create_or_update_membership(nick)
        else
          delete_membership(nick)
        end
      end

      @connection.on(IRC::Message::QUIT) do |message|
        if prefix = message.prefix
          nick, _rest = prefix.split('!')
          delete_membership(nick)
        end
      end

      @connection.on(IRC::Message::KICK) do |message|
        channel, nick = message.parameters
        delete_membership(nick) if channel == @name
      end

      @connection.on(IRC::Message::MODE) do |message|
        channel = message.parameters.first
        return unless channel == @name

        mode  = message.parameters[1]
        flags = mode.chars
        add   = flags.shift == '+'

        flags.each_with_index do |flag, i|
          next unless {'o', 'v'}.includes? flag

          nick    = message.parameters[i+2]
          olduser = find_or_create_membership(nick).to_s

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
            newuser = olduser.starts_with?('@') ? olduser : nick
          end

          create_or_update_membership(newuser)
        end
      end
    end

    def on_message(&block : Message ->)
      @message_handlers << block
    end

    def join
      @connection.send "JOIN #{@name}"
    end

    def part
      @connection.send "PART #{@name}"
    end

    def membership nick : String
      @users.find {|user| user.nick == nick }
    end

    private def find_or_create_membership membership
      membership = Membership.parse(membership)
      entry = @users.find {|user| user == membership }

      unless entry
        entry = membership
        @users << membership
      end

      entry
    end

    private def create_or_update_membership membership
      Membership.parse(membership).tap do |user|
        @users.delete user
        @users << user
      end
    end

    private def delete_membership membership
      @users.delete Membership.parse(membership)
    end
  end
end
