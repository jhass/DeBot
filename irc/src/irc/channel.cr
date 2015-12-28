require "./membership"
require "./message"
require "./modes"

module IRC
  # WITHOUT PARAMETER
  # CHANNELMODE - DESCRIPTION
  #      +n     - No external messages.  Only channel members may talk in
  #               the channel.
  #      +t     - Ops Topic.  Only opped (+o) users may set the topic.
  #      +s     - Secret.  Channel will not be shown in /whois and /list etc.
  #      +p     - Private.  Disables /knock to the channel.
  #      +m     - Moderated.  Only opped/voiced users may talk in channel.
  #      +i     - Invite only.  Users need to be /invite'd or match a +I to
  #               join the channel.
  #      +r, +R - Registered users only.  Only users identified to services
  #               may join.
  #      +r     - The channel is registered (settable by services only) (UnrealIRCd)
  #      +c, +S - No color.  All color codes in messages are stripped.
  #      +g     - Free invite.  Everyone may invite users.  Significantly
  #               weakens +i control.
  #      +z     - Op moderated.  Messages blocked by +m, +b and +q are instead
  #               sent to ops.
  #      +L     - Large ban list.  Increase maximum number of +beIq entries.
  #               Only settable by opers.
  #      +P     - Permanent.  Channel does not disappear when empty.  Only
  #               settable by opers.
  #      +F     - Free target.  Anyone may set forwards to this (otherwise
  #               ops are necessary).
  #      +Q     - Disable forward.  Users cannot be forwarded to the channel
  #               (however, new forwards can still be set subject to +F).
  #      +C     - Disable CTCP. All CTCP messages to the channel, except ACTION,
  #               are disallowed.
  #      +A     - Server/Net Admin only channel (settable by Admins)
  #      +G     - Filters out all Bad words in messages with <censored> [o]
  #      +K     - /KNOCK is not allowed [o]
  #      +M     - Must be using a registered nick (+r), or have voice access to talk [o]
  #      +N     - No Nickname changes are permitted in the channel [o]
  #      +O     - IRC Operator only channel (settable by IRCops)
  #      +Q     - No kicks allowed [o]
  #      +T     - No NOTICEs allowed in the channel [o]
  #      +u     - Auditorium mode (/names and /who #channel only show channel ops) [q]
  #      +V     - /INVITE is not allowed [o]
  #      +z     - Only Clients on a Secure Connection (SSL) can join [o]
  #      +Z     - All users on the channel are on a Secure connection (SSL) [server]
  #               (This mode is set/unset by the server. Only if the channel is also +z)

  # WITH PARAMETER
  # CHANNELMODE - DESCRIPTION
  #      +f     - Forward.  Forwards users who cannot join because of +i, (Freenode)
  #               +j, +l or +r.
  #               PARAMS: /mode #channel +f #channel2
  #      +f     - Flood protection (for more info see /HELPOP CHMODEF) [o] (UnrealIRCD)
  #      +j     - Join throttle.  Limits number of joins to the channel per time.
  #               PARAMS: /mode #channel +j count:time
  #      +k     - Key.  Requires users to issue /join #channel KEY to join.
  #               PARAMS: /mode #channel +k key
  #      +l     - Limit.  Impose a maximum number of LIMIT people in the channel.
  #               PARAMS: /mode #channel +l limit
  #      +L <chan2> - Channel link (If +l is full, the next user will auto-join <chan2>) [q]
  class Channel
    MEMBERHSIP_MODES = {'v', 'b', 'q', 'e', 'o', 'I', 'h', 'a'}

    getter name
    getter modes

    def initialize(@connection, @name)
      @modes = Modes.new
      @message_handlers = [] of Message ->

      @connection.on Message::PRIVMSG, Message::NOTICE do |message|
        target = message.parameters.first
        @message_handlers.each &.call(message) if target == @name
      end

      @connection.on Message::MODE do |message|
        target = message.parameters.first
        modes  = message.parameters[1..-1].join(' ')

        if target == @name
          Modes::Parser.parse(modes) do |modifier, flag, parameter|
            unless MEMBERHSIP_MODES.includes?(flag)
              if modifier == '+'
                @modes.set flag, parameter
              else
                @modes.unset flag, parameter
              end
            end
          end
        end
      end
    end

    def on_message(&block : Message ->)
      @message_handlers << block
    end

    def clear_handlers
      @message_handlers.clear
    end

    def join
      @connection.send "JOIN #{@name}"
    end

    def part
      @connection.send "PART #{@name}"
    end

    {% for item in [{'b', "banned"}, {'q', "quieted"}, {'e', "exempted"}, {'I', "invited"}] %}
      {% flag = item[0] %}
      {% name = item[1] %}
      def query_{{name.id}}
      end
    {% end %}

    {% for item in [{['n'], "no_external"}, {['t'], "topic_locked"}, {['s'], "secret"},
                    {['p'], "pivate"}, {['m'], "moderated"}, {['i'], "invite_only"},
                    {['r', 'R'], "registered_only"}, {['c', 'S'], "no_colors"}, {['g'], "free_invite"},
                    {['z'], "reduced_moderation"}, {['L'], "large_banlist"}, {['P'], "permanent"},
                    {['F'], "free_target"}, {['Q'], "disabled_forward"}, {['C'], "no_ctcp"},
                    {['A'], "admin_channel"}, {['K'], "no_knock"}, {['N'], "no_nick_changes"},
                    {['O'], "operator_channel"}, {['V'], "no_invite"}, {['z'], "secure_only"},
                    {['Q'], "no_kicks"}, {['T'], "no_notices"}, {['u'], "auditorium"},
                    {['Z'], "all_secure"}] %}
      {% flags = item[0] %}
      {% name  = item[1] %}
      def {{name.id}}?
        {% for flag in flags %}
          @modes.set?({{flag}}) ||
        {% end %}
        false # Cheat post fence problem
      end
    {% end %}

    {% for item in [{'j', "join_throttle"}, {'k', "key"}, {'l', "limit"}, {'L', "link"}] %}
      {% flag = item[0] %}
      {% name = item[1] %}
      def {{name.id}}
        @modes.get {{flag}}
      end
    {% end %}
  end
end
