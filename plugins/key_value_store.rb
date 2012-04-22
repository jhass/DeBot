class KeyValueStore
  include Cinch::Plugin

  def initialize(*args)
    super
    @storage  = bot.config.storage.backend.new(@bot.config.storage, self)
    storage[:key_values] ||= {}
  end

  attr_reader :storage

  match /([^=\s]+)/, method: :get, prefix: /^(?:!i |\?)/
  match /([^=\s]+)=(.+)/, method: :set, prefix: /^(?:!i |\?)/


  def get(m, key)
    storage[:key_values][m.channel.name] ||= {}
    if key == "keys"
      m.reply "I know the following keys for this channel: #{storage[:key_values][m.channel.name].keys.join(", ")}"
    elsif storage[:key_values][m.channel.name].has_key?(key)
      m.reply storage[:key_values][m.channel.name][key]
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
