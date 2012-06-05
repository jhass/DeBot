class KeyValueStore
  include Cinch::Plugin

  def initialize(*args)
    super
    @storage  = bot.config.storage.backend.new(@bot.config.storage, self)
    storage[:key_values] ||= {}
  end

  attr_reader :storage

  set(plugin_name: "keyvaluestore",
      prefix: /^(?:!i\s+|\?)/,
      help: "Usage: !i key/?key [nick], !i key=val/?key=val, !i keys/?keys")

  match /([\w_\-\d]+)(?:\s+([^ ]+))?$/, method: :get
  match /([\w_\-\d]+)=(.+)/, method: :set


  def get(m, key, nick=nil)
    storage[:key_values][m.channel.name] ||= {}
    return if key.start_with?("?") #TODO better regex instead
    nick = "#{nick}: " if nick
    if key == "keys"
      m.reply "I know the following keys for this channel: #{storage[:key_values][m.channel.name].keys.sort.join(", ")}"
    elsif storage[:key_values][m.channel.name].has_key?(key)
      m.reply "#{nick}#{storage[:key_values][m.channel.name][key]}"
    else
      m.reply "No value found for #{key}"
    end
  end

  def set(m, key, value)
    storage[:key_values][m.channel.name] ||= {}
    storage[:key_values][m.channel.name][key] = value
    storage.save
    m.reply "#{m.user.nick}: Set #{key}"
  end
end
