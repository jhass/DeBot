require 'open-uri'

class Password
  include Cinch::Plugin
  set(plugin_name: "password",
      help: "Usage: !password [lang] to shout out a random xkcd-style password (http://xkcd.com/936/)")

  AVAILABLE_DICTS = {"default" => "/usr/share/dict/words",
                     "en" => "/usr/share/dict/american-english",
                     "de" => "/usr/share/dict/ngerman"}

  match /password(\s\w\w)?/
  def execute(m, lang)
    lang ||= "default"
    dict = AVAILABLE_DICTS[lang.strip]
    dict ||= AVAILABLE_DICTS["default"]
    password = `echo "$(shuf -n4 #{dict} | tr '\n' ' ')"`
    m.reply password.downcase
  rescue
    m.reply "I'm out of passwords currently :("
  end
end
