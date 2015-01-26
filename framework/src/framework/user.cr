require "./repository"

module Framework
  class User
    getter nick
    getter user
    getter host
    getter mask

    @@users ||= Repository(String, User).new

    def self.none
      @@none ||= new(nil, nil, nil, nil)
    end

    def self.find_or_create_by_mask mask
      @@users.not_nil!.fetch(mask) { User.parse(mask) }
    end

    def self.parse mask
      local, host = mask.split '@'
      if host
        nick, user = local.split '!'
        user = user[1..-1] if user.starts_with? '~'
        new(nick, user, host, mask)
      else
        new(nil, nil, host, mask)
      end
    end

    def initialize(@nick, @user, @host, @mask)
    end

    def name
      @nick || @user || @host
    end
  end
end
