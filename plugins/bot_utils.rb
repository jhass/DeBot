class BotUtils
  include Cinch::Plugin

  match /join (#[\w\d_-]+)/, method: :join
  def join(m, channel)
    return unless admin?(m.user.nick)
    if bot.channels.include?(channel)
      m.reply "I think I'm already in #{channel} ;)"
    else
      bot.join channel
      synchronize(:settings) do
        Settings.channels << channel
        Settings.save!
      end
    end
  end

  match /part (#[\w\d_-]+)/, method: :part
  def part(m, channel)
    return unless admin?(m.user.nick)
    if bot.channels.include?(channel)
      bot.part channel
      synchronize(:settings) do
        Settings.channels.delete channel
        Settings.save!
      end
    else
      m.reply "I can't leave #{channel} if I'm not there..."
    end
  end

  match /msg ([^ ]+) (.+)/, method: :msg
  def msg(m, dst, msg)
    return unless admin?(m.user.nick)
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

  match /addadmin ([^ ]+)/, method: :add_admin
  def add_admin(m, nick)
    return unless superadmin?(m.user.nick)
    if Settings.admins.include?(nick)
      m.reply "#{nick} is already controlling me."
    else
      synchronize(:settings) do
        Settings.admins << nick
        Settings.save!
        config[:admins] << nick
      end
      m.reply "#{nick} can control me now."
    end
  end

  match /rmadmin ([^ ]+)/, method: :rm_admin
  def rm_admin(m, nick)
    return unless superadmin?(m.user.nick)
    if Settings.admin.include?(nick)
      synchronize(:settings) do
        Settings.admins.delete nick
        Settings.save!
        config[:admins].delete nick
      end
      m.reply "#{nick} has no control over me anymore."
    else
      m.reply "#{nick} already has no control over me."
    end
  end

  private
  def admin?(nick)
    config[:admins].include?(nick) || superadmin?(nick)
  end

  def superadmin?(nick)
    config[:superadmin] == nick
  end
end
