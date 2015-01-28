require "irc/message"

require "./repository"
require "./message"
require "./bot"

module Framework
  class Channel
    record Membership, user, opped, voiced do
      def_equals_and_hash user.nick

      def opped?
        opped
      end

      def voiced?
        voiced
      end

      def self.parse membership, context
        opped = membership[0] == '@'
        voiced = membership[0] == '+'
        nick = opped || voiced ? membership[1..-1] : membership
        new User.from_nick(nick, context), opped, voiced
      end
    end

    getter name

    @@channels = Repository(String, Channel).new

    def self.from_name name : String, context
      @@channels.fetch(name) { new(name, context) }
    end

    private def initialize(@name : String, @context : Bot)
      @memberships = [] of Membership
    end

    def update_userlist memberships : Array(String)
      memberships.each do |membership|
        update_userlist(membership)
      end
    end

    def update_userlist membership : String
      membership = Membership.parse(membership, @context)
      index = @memberships.index(membership)
      if index
        @memberships[index] = membership
      else
        @memberships << membership
      end
    end

    def membership user : User
      membership user.nick
    end

    def membership nick : String
      @memberships.find {|membership| membership.user.nick == nick }
    end

    def send text : String
      Message.new(@context, @name, text).send
    end

    def in_channel? user : User
      in_channel? user.nick
    end

    def in_channel? nick : String
      !membership(nick).nil?
    end

    def opped? user : User
      opped? user.nick
    end

    def opped? nick : String
      membership(nick).try(&.opped?) || false
    end

    def voiced? user : User
      voiced? user.nick
    end

    def voiced? nick : String
      membership(nick).try(&.voiced?) || false
    end

    def ban user : User
      ban user.mask
    end

    def ban mask : Mask
      ban mask.to_s
    end

    def ban mask : String
      @context.connection.send IRC::Message::MODE, @name, "+b", mask
    end

    def unban user : User
      unban user.mask
    end

    def unban mask : Mask
      unban mask.to_s
    end

    def unban mask : String
      @context.connection.send IRC::Message::MODE, @name, "-b", mask
    end

    def kick user : User, reason=nil
      kick user.nick, reason
    end

    def kick nick : String, reason=nil
      params = [@name, nick]
      params << reason if reason
      @context.connection.send IRC::Message::KICK, params
    end
  end
end
