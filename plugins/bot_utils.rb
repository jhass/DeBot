class BotUtils
  include Cinch::Plugin

  match /join (#[\w\d_-]+)/, method: :join
  def join(m, channel)
    if config[:admins].include?(m.user.nick)
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
  end

  match /part (#[\w\d_-]+)/, method: :part
  def part(m, channel)
    if config[:admins].include?(m.user.nick)
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
  end
end
