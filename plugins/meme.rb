require 'open-uri'

class Meme
  include Cinch::Plugin
  set(plugin_name: "meme",
      help: "Usage: !meme to shout out a meme from automeme.net")

  match /meme/
  def execute(m)
    open("http://api.automeme.net/text?lines=1") do |f|
      m.reply f.read
    end
  rescue
    m.reply "I'm out of memes currently :("
  end
end
