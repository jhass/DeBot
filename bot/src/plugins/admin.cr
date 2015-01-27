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
  match /^!(msg|sayto)\s+([^ ]+)\s+(.+)/
  match /^!(quit)/

  def execute msg, match
    return unless @admins.includes? msg.sender.nick


    case match[1]
    when "join", "part", "sayto", "msg"
      with_channel msg, match
    when "quit"
      context.connection.quit
    end
  end

  def with_channel msg, match
    channel = match[2].empty? ? msg.channel.name : match[2]

    case match[1]
    when "join"
      return unless channel
      msg.context.join channel
    when "part"
      return unless channel
      msg.context.part channel
    when "msg", "sayto"
      sayto msg, match[2], match[3]
    end
  end

  def sayto msg, dst, message
    if dst.starts_with? '#'
      if context.channels.includes?(dst)
        channel(dst).send message
      else
        msg.reply "I'm not in #{dst}."
      end
    else
      user(dst).send message
    end
  end
end
