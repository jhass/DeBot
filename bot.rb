require 'cinch'
require 'cinch/configuration/storage'
require 'cinch/storage/yaml'

require 'cinch/plugins/identify'
require 'cinch/plugins/downforeveryone'
require 'cinch/plugins/title'

require './settings'

require './plugins/google'
require './plugins/memo'
require './plugins/down_for_everyone'
require './plugins/title'
require './plugins/key_value_store'
require './plugins/translation_status'
require './plugins/update_diaspora'
require './plugins/pod_updated'
require './plugins/what_the_commit'
require './plugins/russian_roulette'
require './plugins/feeds'
require './plugins/bot_utils'

Settings.setup!

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = Settings.nick
    c.server = Settings.server
    c.port = Settings.port
    c.channels = Settings.channels

    c.storage = Cinch::Configuration::Storage.new
    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./yaml/"
    c.storage.autosave = true

    c.plugins.plugins = []

    if Settings.identify.enabled
      c.plugins.plugins << Cinch::Plugins::Identify
      c.plugins.options[Cinch::Plugins::Identify] = {
        :username => Settings.nick,
        :password => Settings.identify.password,
        :type => Settings.identify.type
      }
    end

    if Settings.feeds.keys.size > 0
      c.plugins.plugins << Feeds
      c.plugins.options[Feeds] = Settings.feeds
    end

    if Settings.admins && Settings.admins.size > 0
      c.plugins.plugins << BotUtils
      c.plugins.options[BotUtils] = {
        :admins => Settings.admins,
        :superadmin => Settings.superadmin
      }
    end

    c.plugins.plugins += [
      Google,
      Memo,
      Cinch::Plugins::DownForEveryone,
      Cinch::Plugins::Title,
      KeyValueStore,
      TranslationStatus,
      UpdateDiaspora,
      PodUpdated,
      WhatTheCommit,
      RussianRoulette
    ]
  end

  on :message do |m|
    msgs = [ "Ich mag dich", "Hast recht,", "Genau,", "Richtig,", "Ihr redet alle blödsinn, Recht hat nur", "Jawohl," "Da stimme ich dir zu",
             "Ich liebe dich so viel dass ich oft an dir in der dusche denk", "Ack ", "Aye", "Jo", "Wie geht's dir", "Denk ich auch,",
             "Schön,", "Du bist der Wind in meinen Flügeln", "Genau meine Meinung"]
    m.reply "#{msgs[rand(msgs.size)]} #{m.user.nick}" if m.user.nick == "paddyez" && rand(30) == 0
  end
end

bot.loggers.level = :info

bot.start
