require "thread/repository"

require "./modes"
require "./membership"

module IRC
  # USERMODE     DESCRIPTION
  #     +A     - Is a Server Administrator
  #     +a     - Is a Services Administrator
  #     +B     - Marks you as being a Bot
  #     +C     - Is a Co Administrator
  #     +D, +d - Deaf - ignores all channel messages.
  #     +g     - "caller id" mode only allow accept clients to message you (Freenode)
  #     +g     - Can read & send to GlobOps, and LocOps (UnrealIRCD)
  #     +G     - Filters out all Bad words in your messages with <censored>
  #     +h     - Available for Help (Help Operator)
  #     +H     - Hide IRCop status in /WHO and /WHOIS. (IRC Operators only)
  #     +i     - Designates this client 'invisible'.
  #     +I     - Hide an oper's idle time (in /whois output) from regular users.
  #     +N     - Is a Network Administrator
  #     +o     - Designates this client is an IRC Operator.
  #     +O     - Local IRC Operator
  #     +p     - Hide all channels in /whois and /who
  #     +q     - Only U:lines can kick you (Services Admins/Net Admins only)
  #     +Q     - Prevents you from being affected by channel forwarding.
  #     +R     - Allows you to only receive PRIVMSGs/NOTICEs from registered (+r) users
  #     +r     - Identifies the nick as being Registered (settable by services only)
  #     +s     - Can listen to Server notices
  #     +S     - For Services only. (Protects them)
  #     +T     - Prevents you from receiving CTCPs
  #     +t     - Says that you are using a /VHOST
  #     +V     - Marks the client as a WebTV user
  #     +v     - Receive infected DCC send rejection notices
  #     +w     - Can listen to Wallop messages
  #     +W     - Lets you see when people do a /WHOIS on you (IRC Operators only)
  #     +x     - Gives the user Hidden Hostname (security)
  #     +Z, +z - Is connected via SSL (cannot be set or unset).
  class User
    property authname : String|Bool?
    property realname : String?
    getter channels
    getter mask
    getter modes
    delegate nick, mask
    delegate user, mask
    delegate host, mask

    def initialize(@mask : Mask)
      @authname = nil
      @realname = nil
      @channels = Repository(String, Membership).new
      @modes    = Modes.new
    end

    def name
      nick || user || @realname || @authname || host
    end

    def mode(flag, gained)
      if gained
        @modes.set flag
      else
        @modes.unset flag
      end
    end

    {% for item in [{['A'], "server_admin"}, {['a'], "service_admin"}, {['B'], "bot"},
                           {['C'], "co_admin"}, {['D', 'd'], "deaf"}, {['h'], "available_for_help"},
                           {['i'], "invisible"}, {['N'], "network_admin"}, {['o'], "operator"},
                           {['O'], "local_operator"}, {['r'], "registered"}, {['S'], "service"},
                           {['w'], "receive_wallops"}, {['z', 'Z'], "secure"},] %}
      {% flags = item[0] %}
      {% name  = item[1] %}
      def {{name.id}}?
        {% for flag in flags %}
          @modes.set?({{flag}}) ||
        {% end %}
        false # Cheat post fence problem
      end
    {% end %}
  end
end
