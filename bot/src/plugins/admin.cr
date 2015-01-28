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
  match /^!((?:de)?op)(?:\s+(\w+))?/

  def execute msg, match
    return unless @admins.includes? msg.sender.nick

    case match[1]
    when "join", "part", "sayto", "msg"
      with_channel msg, match
    when "op"
      op :op, msg, match[2]
    when "deop"
      op :deop, msg, match[2]
    when "quit"
      context.connection.quit
    end
  end

  def with_channel msg, match
    channel = match[2]
    if channel.empty?
      return unless msg.channel?
      channel = msg.channel.name
    end

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

  def op mode, msg, target
    return unless msg.channel?

    target = target.empty? ? bot : user(target)
    if !msg.channel.has? target
      msg.reply "#{target.nick} isn't in this channel."
    elsif (msg.channel.opped?(target) ? :op : :deop) == mode
      msg.reply "No change necessary."
    elsif msg.channel.opped? bot
      case mode
      when :op
        msg.channel.op target
      when :deop
        msg.channel.deop target
      end
    else
      user("ChanServ").send "#{mode.to_s.upcase} #{msg.channel.name} #{target.nick}"
    end
  end
end
