require "framework/plugin"

class Admin
  include Framework::Plugin

  def initialize @admins : Enumerable(String)
  end

  #channel    =  ( "#" / "+" / ( "!" channelid ) / "&" ) chanstring
  #              [ ":" chanstring ]
  #chanstring = ; any octet except NUL, BELL, CR, LF, " ", "," and ":"
  #channelid = ; 5( A-Z / 0-9 )

  match /^!(join|part)\s+(#[^\s,:]+)?/

  def execute msg, match
    # pp @admins
    # pp msg
    return unless @admins.includes? msg.sender.nick

    channel = match[2].empty? ? msg.channel : match[2]
    return unless channel

    case match[1]
    when "join"
      msg.context.join channel
    when "part"
      msg.context.part channel
    end
  end
end
