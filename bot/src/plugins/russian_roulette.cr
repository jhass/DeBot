require "framework/plugin"

class RussianRoulette
  include Framework::Plugin

  REASONS = [
    "You just shot yourself!",
    "Suicide is never the answer.",
    "If you wanted to leave, you could have just said so...",
    "Good thing these aren't real bullets...",
    "That's gotta hurt..."
  ]
  ALSO_BAN = true
  BAN_TIME = 30
  CHAMBERS = 6
  @@chambers = CHAMBERS

  match /^!roul(?:ette)?/

  def execute msg, _match
    return unless msg.channel?

    msg.reply "*pull*..."
    in(3) do
      if @@chambers == 1
        has_bullet = true
        @@chambers = CHAMBERS
      else
        has_bullet = (rand(@@chambers) == 0)
      end

      if has_bullet
        if msg.channel.opped? bot
          msg.channel.ban msg.sender if ALSO_BAN
          msg.channel.kick msg.sender, "{ *BANG* #{REASONS[rand(REASONS.size)]} }"
          in(BAN_TIME) { msg.channel.unban msg.sender } if ALSO_BAN
        else
          msg.reply "#{msg.sender.nick}: #{REASONS[rand(REASONS.size)]}"
        end
      else
        msg.reply "-click-"
        @@chambers -= 1
      end
    end
  end
end
