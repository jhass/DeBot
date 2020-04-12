require "framework/plugin"

class Admin
  include Framework::Plugin

  config({
    admins:      {type: Array(String), nilable: true},
    superadmins: {type: Array(String), default: [] of String},
  })

  def admins
    config.admins ||= [] of String
  end

  def superadmin?(user)
    return false unless user.authname
    config.superadmins.includes? user.authname
  end

  def admin?(user)
    return true if superadmin? user
    return false unless user.authname
    admins.includes? user.authname
  end

  # channel    =  ( "#" / "+" / ( "!" channelid ) / "&" ) chanstring
  #              [ ":" chanstring ]
  # chanstring = ; any octet except NUL, BELL, CR, LF, " ", "," and ":"
  # channelid = ; 5( A-Z / 0-9 )

  match /^!(join|part)\s+(#[^\s,:]+)?/
  match /^!(msg|sayto|doto)\s+([^ ]+)\s+(.+)/
  match /^!(addadmin|rmadmin)\s+([^ ]+)/
  match /^!(ignore|unignore)\s+([^ ]+)/
  match /^!(enable|disable)\s+(#[^\s,:]+)\s+([a-zA-Z]+)/
  match /^!(enable|disable)\s+([a-zA-Z]+)$/
  match /^!((?:de)?op)(?:\s+(\w+))?$/
  match /^!(quit|reload)$/

  def execute(msg, match)
    return unless admin?(msg.sender)

    case match[1]
    when "join", "part", "sayto", "msg", "doto"
      with_channel msg, match
    when "addadmin"
      add_admin msg, match[2]
    when "rmadmin"
      remove_admin msg, match[2]
    when "ignore"
      add_ignore msg, match[2]
    when "unignore"
      remove_ignore msg, match[2]
    when "enable", "disable"
      channel = match[3]? ? channel(match[2]) : msg.channel
      plugin = match[3]? ? match[3] : match[2]
      if match[1] == "enable"
        enable_plugin msg, channel, plugin
      else
        disable_plugin msg, channel, plugin
      end
    when "op"
      op :op, msg, match[2]?
    when "deop"
      op :deop, msg, match[2]?
    when "reload"
      context.config.reload
      msg.reply "#{msg.sender.nick}: Reloaded configuration."
    when "quit"
      context.connection.quit
    else
      # regexes allow no other values
    end
  end

  def with_channel(msg, match)
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
    when "doto"
      doto msg, match[2], match[3]
    else
      # regexes don't allow other
    end
  end

  def sayto(msg, dst, message)
    sendto(msg, dst) do |target|
      target.send message
    end
  end

  def doto(msg, dst, message)
    sendto(msg, dst) do |target|
      target.action message
    end
  end

  def sendto(msg, dst)
    if dst.starts_with? '#'
      if context.channels.includes?(dst)
        yield channel(dst)
      else
        msg.reply "I'm not in #{dst}."
      end
    else
      yield user(dst)
    end
  end

  def op(mode, msg, target)
    return unless msg.channel?

    target = target ? user(target) : bot
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
      else
        # either or above
      end
    else
      user("ChanServ").send "#{mode.to_s.upcase} #{msg.channel.name} #{target.nick}"
    end
  end

  def add_admin(msg, nick)
    return unless superadmin? msg.sender

    new_admin = user(nick)

    if admin? new_admin
      msg.reply "#{msg.sender.nick}: #{nick} is already an admin."
    elsif bot.nick == nick
      msg.reply "#{msg.sender.nick}: That makes no sense."
    else
      authname = new_admin.authname
      if authname.is_a? String
        admins << authname
        config.save(context.config)
        msg.reply "#{msg.sender.nick}: Added #{nick} to admins."
      else
        msg.reply "#{msg.sender.nick}: #{nick} is not authenticated."
      end
    end
  end

  def remove_admin(msg, nick)
    return unless superadmin? msg.sender

    authname = user(nick).authname
    authname = {authname, nick}.find { |name| admins.includes? name }

    if authname
      admins.delete authname
      config.save(context.config)
      msg.reply "#{msg.sender.nick}: Removed #{nick} from admins."
    else
      msg.reply "#{msg.sender.nick}: #{nick} is not an admin."
    end
  end

  def add_ignore(msg, nick)
    return unless admin? msg.sender

    unless context.config.ignores.includes? nick
      context.config.ignores << nick
      context.config.save
      msg.reply "#{msg.sender.nick}: I will ignore #{nick} now."
    else
      msg.reply "#{msg.sender.nick}: I ignore #{nick} already."
    end
  end

  def remove_ignore(msg, nick)
    return unless admin? msg.sender

    if context.config.ignores.includes? nick
      context.config.ignores.delete(nick)
      context.config.save
      msg.reply "#{msg.sender.nick}: I will no longer ignore #{nick}."
    else
      msg.reply "#{msg.sender.nick}: I do not ignore #{nick}."
    end
  end

  def enable_plugin(msg, channel, name)
    unless context.config.plugins.has_key? name
      msg.reply "#{msg.sender.nick}: Unknown plugin #{name}."
      return
    end

    plugin_config = context.config.plugins[name].config

    if plugin_config.listens_to? channel
      msg.reply "#{msg.sender.nick}: #{name} is already enabled."
      return
    end

    plugin_config.channels!.add channel
    plugin_config.save(context.config)

    msg.reply "#{msg.sender.nick}: Enabled #{name}."
  end

  def disable_plugin(msg, channel, name)
    unless context.config.plugins.has_key? name
      msg.reply "#{msg.sender.nick}: Unknown plugin #{name}."
      return
    end

    plugin_config = context.config.plugins[name].config

    unless plugin_config.listens_to? channel
      msg.reply "#{msg.sender.nick}: #{name} is already disabled."
      return
    end

    plugin_config.channels!.remove channel
    plugin_config.save(context.config)

    msg.reply "#{msg.sender.nick}: Disabled #{name}."
  end
end
