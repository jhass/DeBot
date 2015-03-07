require "framework/plugin"

class Admin
  include Framework::Plugin

  config({
    admins: {type: Array(String), nilable: true},
    superadmins: {type: Array(String), default: [] of String}
  })

  def admins
    config.admins ||= [] of String
  end

  def superadmin? user
    config.superadmins.includes? user.nick
  end

  def admin? user
    return true if superadmin? user
    admins.includes? user.nick
  end

  #channel    =  ( "#" / "+" / ( "!" channelid ) / "&" ) chanstring
  #              [ ":" chanstring ]
  #chanstring = ; any octet except NUL, BELL, CR, LF, " ", "," and ":"
  #channelid = ; 5( A-Z / 0-9 )

  match /^!(join|part)\s+(#[^\s,:]+)?/
  match /^!(msg|sayto)\s+([^ ]+)\s+(.+)/
  match /^!(quit|reload)/
  match /^!(addadmin|rmadmin)\s+([^ ]+)/
  match /^!((?:de)?op)(?:\s+(\w+))?/
  match /^!(enable|disable)\s+([a-zA-Z]+)/

  def execute msg, match
    return unless admin?(msg.sender)

    case match[1]
    when "join", "part", "sayto", "msg"
      with_channel msg, match
    when "addadmin"
      add_admin msg, match[2]
    when "rmadmin"
      rm_admin msg, match[2]
    when "enable"
      enable_plugin msg, match[2]
    when "disable"
      disable_plugin msg, match[2]
    when "op"
      op :op, msg, match[2]
    when "deop"
      op :deop, msg, match[2]
    when "reload"
      context.config.reload_plugins
      msg.reply "#{msg.sender.nick}: Reloaded plugin configuration."
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
      msg.reply "#{msg.sender.nick}: #{target.nick} isn't in this channel."
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

  def add_admin msg, nick
    return unless superadmin? msg.sender

    if admin? user(nick)
      msg.reply "#{msg.sender.nick}: #{nick} is already an admin."
    elsif bot.nick == nick
      msg.reply "#{msg.sender.nick}: That makes no sense."
    else
      admins << nick
      config.save
      msg.reply "#{msg.sender.nick}: Added #{nick} to admins."
    end
  end

  def rm_admin msg, nick
    return unless superadmin? msg.sender

    if admin? user(nick)
      admins.delete nick
      config.save
      msg.reply "#{msg.sender.nick}: Removed #{nick} from admins."
    else
      msg.reply "#{msg.sender.nick}: #{nick} is not an admin."
    end
  end

  def enable_plugin msg, name
    unless context.config.plugins.has_key? name
      msg.reply "#{msg.sender.nick}: Unknown plugin #{name}."
      return
    end

    plugin_config = context.config.plugins[name].config

    if plugin_config.wants? msg
      msg.reply "#{msg.sender.nick}: #{name} is already enabled."
      return
    end

    plugin_config.channels!.add msg.channel
    plugin_config.save

    msg.reply "#{msg.sender.nick}: Enabled #{name}."
  end

  def disable_plugin msg, name
    unless context.config.plugins.has_key? name
      msg.reply "#{msg.sender.nick}: Unknown plugin #{name}."
      return
    end

    plugin_config = context.config.plugins[name].config

    unless plugin_config.wants? msg
      msg.reply "#{msg.sender.nick}: #{name} is already disabled."
      return
    end

    plugin_config.channels!.remove msg.channel
    plugin_config.save

    msg.reply "#{msg.sender.nick}: Disabled #{name}."
  end
end
