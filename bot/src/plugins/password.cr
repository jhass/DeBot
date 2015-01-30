require "framework/plugin"

class Password
  include Framework::Plugin
  AVAILABLE_DICTS = {
    "default" => "/usr/share/dict/words",
    "en"      => "/usr/share/dict/american-english",
    "de"      => "/usr/share/dict/ngerman"
  }

  match /^!password\s*$/
  match /^!password\s+(\w\w)/
  def execute msg, match
    lang = match[1]? || "default"
    dict = AVAILABLE_DICTS[lang.strip]
    dict ||= AVAILABLE_DICTS["default"]
    password = `echo "$(shuf -n4 #{dict} | tr '\n' ' ')"`.delete('\'')
    msg.reply password.downcase
  rescue
    msg.reply "I'm out of passwords currently :("
  end
end
