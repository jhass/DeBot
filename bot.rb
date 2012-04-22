require 'cinch'
require 'cinch/configuration/storage'
require 'cinch/storage/yaml'

require 'cinch/plugins/downforeveryone'
require 'cinch/plugins/title'

require './plugins/google'
require './plugins/memo'
require './plugins/downforeveryone'
require './plugins/title'
require './plugins/key_value_store'
require './plugins/translation_status'
require './plugins/update_diaspora'
require './plugins/pod_updated'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "DeBotNG"
    c.server = "chat.eu.freenode.net"
    c.channels = ["#diaspora-de"]

    c.storage = Cinch::Configuration::Storage.new
    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./yaml/"
    c.storage.autosave = true

    c.plugins.plugins = [
      Google,
      Memo,
      Cinch::Plugins::DownForEveryone,
      Cinch::Plugins::Title,
      KeyValueStore,
      TranslationStatus,
      UpdateDiaspora,
      PodUpdated
    ]
  end
  
  on :message, "hello" do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :message, "good bye" do |m|
    m.reply "Y U LEAVE ME, #{m.user.nick}"
  end
end

bot.start
