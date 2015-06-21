module IRC
  # CHANNELMODE - DESCRIPTION
  #      +v     - Voice.  Allows a user to talk in a +m channel.  Noted by +nick.
  #               PARAMS: /mode #channel +v nick
  #      +o     - Op.  Allows a user full control over the channel.
  #               PARAMS: /mode #channel +o nick
  #      +b     - Ban.  Prevents a user from entering the channel, and from
  #               sending or changing nick if they are on it, based on a
  #               nick!ident@host match.
  #               PARAMS: /mode #channel +b nick!user@host
  #      +q     - Quiet.  Prevents a user from sending to the channel or changing
  #               nick, based on a nick!ident@host match.
  #               PARAMS: /mode #channel +q nick!user@host (Freenode)
  #      +q     - Gives Owner status to the user (UnrealIRCD)
  #      +e     - Exempt.  Allows a user to join a channel and send to it even if
  #               they are banned (+b) or quieted (+q), based on a nick!ident@host
  #               match.
  #               PARAMS: /mode #channel +e nick!user@host
  #      +I     - Invite Exempt.  Allows a user to join a +i channel without an
  #               invite, based on a nick!user@host match.
  #               PARAMS: /mode #channel +I nick!user@host
  #               # +v <nickname>            - Gives Voice to the user (May talk if chan is +m)
  #      +h     - Gives HalfOp status to the user (Limited op access)
  #      +a     - Gives Channel Admin to the user

  class Membership
    getter  channel
    getter? active
    getter  modes

    def initialize @channel
      @active = false
      @modes  = Modes.new
    end

    def join
      @active = true
    end

    def part
      @active = false
      @modes.unset 'v'
      @modes.unset 'o'
      @modes.unset 'h'
      @modes.unset 'a'
    end

    def mode flag, gained, parameter=nil
      if gained
        @modes.set flag, parameter
      else
        @modes.unset flag, parameter
      end
    end

    {% for item in [{'v', "voiced"}, {'o', "op"}, {'q', "owner"}, {'h', "halfop"}, {'a', "admin"}] %}
      {% flag = item[0] %}
      {% name = item[1] %}
      def {{name.id}}?
        @modes.set? {{flag}}
      end
    {% end %}

    {% for item in [{'b', "banned"}, {'q', "quieted"}, {'e', "exempted"}, {'I', "invited"}] %}
      {% flag = item[0] %}
      {% name = item[1] %}
      def {{name.id}}?
        set = @modes.set? {{flag}}, false
        return set if set

        channel.query_{{name.id}}
        @modes.set? {{flag}}, false
      end
    {% end %}
  end
end
