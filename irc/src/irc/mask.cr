module IRC
  class Mask
    property! nick
    property user
    property host
    def_equals_and_hash nick

    def self.parse mask
      if mask.includes? '@'
        local, host = mask.split '@'
      else
        local = mask
      end

      if local.includes? '!'
        nick, user = local.split '!'
      else
        nick = local
      end

      new nick, user, host
    end

    def initialize(@nick : String, @user : String?, @host : String?)
    end

    def update mask
      if mask.nick == @nick
        @user = mask.user if mask.user
        @host = mask.host if mask.host
      end
    end

    def matches? other
      return true if !has_wildcard? && nick == other.nick && user == other.user && host == other.host
      return false unless has_wildcard?

      !to_regex.match(other).nil?
    end

    def has_wildcard?
      @has_wildcards ||= [@nick, @user, @host].any? {|part|
        part && contains_wildcard?(part)
      }
    end

    def to_regex
      @regex = Regex.new(Regex.escape(to_s)) unless has_wildcard?
      return @regex if @regex

      wildcard = Regex.escape(to_s)
      wildcard = wildcard.gsub(/(?<!\\)\\\?/, ".?")
      wildcard = wildcard.gsub(/(?<!\\)\\\*/, ".*")
      @regex = Regex.new wildcard
    end

    def to_s(io)
      io << @nick
      io << '!' << @user if @user
      io << '@' << @host if @host
    end

    private def contains_wildcard? part
      prev = nil
      part.each_char do |char|
        return true if prev != '\\' && (char == '*' || char == '?')
        prev = char
      end
    end
  end
end
