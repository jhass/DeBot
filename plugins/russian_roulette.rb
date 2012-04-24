class RussianRoulette
  include Cinch::Plugin

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

  def initialize(*args)
    super
    @@chambers = CHAMBERS
  end

  set(plugin_name: "roulette",
      help: "Usage: !roul/!roulette takes the gun right to your head and pulls the trigger. There's one bullet in #{CHAMBERS} chambers")

  match /roul(?:ette)?/

  def execute(m)
    m.reply "*pull*..."
    Timer(3, :shots => 1) do
      has_bullet = (rand(@@chambers) == 0)
      if @@chambers == 1
        has_bullet = true
        @@chambers = CHAMBERS
      end
  
      if has_bullet
        if m.channel.opped? m.bot
          m.channel.ban m.user if ALSO_BAN
          m.channel.kick m.user, "{ *BANG* #{REASONS[rand(REASONS.size)]} }"
          Timer(BAN_TIME, :shots => 1) { m.channel.unban m.user } if ALSO_BAN
        else
          m.reply "#{m.user.nick}: #{REASONS[rand(REASONS.size)]}"
        end
      else
        m.reply "-click-"
        @@chambers -= 1
        m.reply "#{@@chambers} left"
      end
    end
  end
end
