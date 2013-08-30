class BotUtils
  include Cinch::Plugin

  match /join\s+(#[#\w\d_-]+)/, method: :join
  def join(m, channel)
    return unless admin?(m.user)
    if bot.channels.include?(channel)
      m.reply "I think I'm already in #{channel} ;)"
    else
      bot.join channel
      synchronize(:settings) do
        settings.channels << channel
        settings.save!
      end
    end
  end

  match /part\s+(#[#\w\d_-]+)/, method: :part
  def part(m, channel)
    return unless admin?(m.user)
    if bot.channels.include?(channel)
      bot.part channel
      synchronize(:settings) do
        settings.channels.delete channel
        settings.save!
      end
    else
      m.reply "I can't leave #{channel} if I'm not there..."
    end
  end

  match /(?:msg|sayto)\s+([^ ]+)\s+(.+)/, method: :msg
  def msg(m, dst, msg)
    return unless admin?(m.user)
    if dst.start_with?('#')
      if bot.channels.include?(dst)
        Channel(dst).send msg
      else
        m.reply "I'm not in #{dst}."
      end
    else
      User(dst).send msg
    end
  end

  match /addadmin\s+([^ ]+)/, method: :add_admin
  def add_admin(m, nick)
    return unless superadmin?(m.user)
    if settings.admins.include?(nick)
      m.reply "#{nick} is already controlling me."
    else
      synchronize(:settings) do
        settings.admins << nick
        settings.save!
        config[:admins] << nick
      end
      m.reply "#{nick} can control me now."
    end
  end

  match /rmadmin\s+([^ ]+)/, method: :rm_admin
  def rm_admin(m, nick)
    return unless superadmin?(m.user)
    if settings.admins.include?(nick)
      synchronize(:settings) do
        settings.admins.delete nick
        settings.save!
        config[:admins].delete nick
      end
      m.reply "#{nick} has no control over me anymore."
    else
      m.reply "#{nick} already has no control over me."
    end
  end

  match /listplugins/, method: :list_plugins
  def list_plugins(m)
    return unless admin?(m.user)
    m.reply bot.plugins.map {|plugin| plugin.class.plugin_name }.join(", ")
  end

  match /unloadplugin (\w+)/, method: :unload_plugin
  def unload_plugin(m, plugin)
    return unless admin?(m.user)
    if plugin = plugin_instance(plugin)
      bot.plugins.unload_plugin plugin_instance(plugin).class
      m.reply "#{plugin} unloaded"
    else
      m.reply "#{plugin} doesn't seem to be loaded"
    end
  end

  match /(?:re)?loadplugin (\w+)/, method: :reload_plugin
  def reload_plugin(m, plugin)
    return unless admin?(m.user)
    loaded = "loaded"
    if plugin_loaded?(plugin)
      loaded = "reloaded"
      bot.plugins.reload_plugin plugin_instance(plugin).class
    else
      bot.plugins.load_plugin plugin.to_sym
    end
    m.reply "#{plugin} #{loaded}"
  rescue
    m.reply "#{plugin} couldn't be #{loaded}"
    raise
  end

  match /loglevel (\w+)/, method: :log_level
  def log_level(m, level)
    return unless superadmin?(m.user)
    levels = [:debug, :log, :info, :warn, :error, :fatal]
    level = level.to_sym
    unless levels.include?(level)
      m.reply "#{level} is not a valid log level. Valid ones are: #{levels.join(", ")}"
      return
    end
    bot.loggers.level = level
    m.reply "ok"
  end

  match /((?:de)?op)$/, method: :op
  match /((?:de)?op) (\w+)/, method: :op
  def op(m, mode, nick=nil)
    return unless admin?(m.user)
    nick ||= bot.nick
    mode.upcase!
    if !m.channel.has_user? nick
      m.reply "#{nick} isn't in this channel"
    elsif (m.channel.opped?(nick) && mode == "OP") || (!m.channel.opped?(nick) && mode == "DEOP")
      m.reply "No change necessary"
    elsif m.channel.opped? bot
      (mode == "OP") ? m.channel.op(nick) : m.channel.deop(nick)
    else
      User("ChanServ").send "#{mode} #{m.channel.name} #{nick}"
    end
  end

  private
  def admin?(user)
    config[:admins].include?(User(user).nick) || superadmin?(user)
  end

  def superadmin?(user)
    config[:superadmin] == User(user).nick
  end

  def plugin_loaded?(plugin)
    plugin_instance(plugin) != nil
  end

  def plugin_instance(plugin)
    (bot.plugins.select {|p| p.class.plugin_name == plugin }).first
  end
end
