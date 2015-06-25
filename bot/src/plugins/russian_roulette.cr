require "framework/plugin"
require "framework/limiter"

class RussianRoulette
  include Framework::Plugin

  ALSO_BAN = true
  BAN_TIME = 30
  CHAMBERS = 6
  LIMITS   = Framework::LimiterCollection(Framework::User).new 3, 60
  REASONS  = [
    "You just shot yourself!",
    "Suicide is never the answer.",
    "If you wanted to leave, you could have just said so...",
    "Good thing these aren't real bullets...",
    "That's gotta hurt..."
  ]

  match /^!roul(?:ette)?/

  def execute msg, _match
    return unless msg.channel?

    return unless LIMITS.pass? msg.sender
    LIMITS.hit msg.sender

    msg.reply "*spin*..."
    msg.reply "*pull*..."
    in(3) do
      has_bullet = (rand(CHAMBERS) == 0)

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
      end
    end
  end
end
