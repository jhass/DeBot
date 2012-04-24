# encoding: utf-8
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

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = settings.nick
    c.server = settings.server
    c.port = settings.port
    c.channels = settings.channels

    c.storage = Cinch::Configuration::Storage.new
    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./yaml/"
    c.storage.autosave = true

    c.plugins.plugins = []

    if settings.identify.enabled
      c.plugins.plugins << Cinch::Plugins::Identify
      c.plugins.options[Cinch::Plugins::Identify] = {
        :username => settings.nick,
        :password => settings.identify.password,
        :type => settings.identify.type
      }
    end

    if settings.feeds.keys.any?
      c.plugins.plugins << Feeds
      c.plugins.options[Feeds] = settings.feeds
    end

    if settings.admins && settings.admins.any?
      c.plugins.plugins << BotUtils
      c.plugins.options[BotUtils] = {
        :admins => settings.admins,
        :superadmin => settings.superadmin
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
    msgs = [ "Ich mag dich", "Hast recht,", "Genau,", "Richtig,", "Ihr redet alle Blödsinn, Recht hat nur", "Jawohl,", "Da stimme ich dir zu",
             "Ich liebe dich so viel dass ich oft an dir in der dusche denk", "Ack ", "Aye", "Jo", "Wie geht's dir", "Denk ich auch,",
             "Schön,", "Du bist der Wind in meinen Flügeln", "Genau meine Meinung"]
    nicks = ["paddyez", "paddy", "p[a]ddy"]
    m.reply "#{msgs[rand(msgs.size)]} #{m.user.nick}" if nicks.include?(m.user.nick) && rand(15) == 0
  end
end

#bot.loggers.level = :info

bot.start
