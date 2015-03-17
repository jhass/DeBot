require "framework/bot"
require "./plugins/hello_world"
require "./plugins/key_value_store"
require "./plugins/diaspora_version"
require "./plugins/crystal_eval"
require "./plugins/admin"
require "./plugins/google"
require "./plugins/diaspora_stats"
require "./plugins/down_for_everyone"
require "./plugins/github_issues"
require "./plugins/password"
require "./plugins/what_the_commit"
require "./plugins/wiki"
require "./plugins/russian_roulette"
require "./plugins/memo"
require "./plugins/wti_status"
require "./plugins/hangman"

bot = Framework::Bot.create do
  config.from_file "settings.json"

  add_plugin Google
  add_plugin DownForEveryone
  add_plugin HelloWorld
  add_plugin DiasporaVersion
  add_plugin DiasporaStats
  add_plugin CrystalEval
  add_plugin Password
  add_plugin WhatTheCommit
  add_plugin RussianRoulette
  add_plugin Admin
  add_plugin KeyValueStore
  add_plugin Memo
  add_plugin GithubIssues
  add_plugin Wiki
  add_plugin WtiStatus
  add_plugin Hangman
end

bot.start
