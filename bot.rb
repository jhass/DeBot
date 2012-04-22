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
end

bot.start
