require "./repository"
require "./mask"
require "./bot"

module Framework
  class User
    getter mask
    property realname
    delegate nick, mask
    delegate user, mask
    delegate host, mask

    @@users = Repository(String, User).new

    def self.from_mask mask : String, context : Bot, realname=nil
      from_mask Mask.parse(mask), context, realname
    end

    def self.from_mask mask : Mask, context : Bot, realname=nil
      @@users.fetch(mask.nick) { new(mask, context, realname) }
    end

    def self.from_nick nick : String, context : Bot, realname=nil
      @@users.fetch(nick) { new(Mask.new(nick, nil, nil), context, realname) }
    end

    private def initialize(@mask : Mask, @context : Bot, @realname=nil)
    end

    def name
      nick || user || host
    end

    def nick= nick
      @@users.rename mask.nick, nick
      mask.nick = nick
    end

    def send text : String
      Message.new(@context, nick, text).send
    end
  end
end
