require "framework/bot"
require "./plugins/admin"
require "./plugins/crystal_eval"
require "./plugins/diaspora_version"
require "./plugins/github_issues"
require "./plugins/hangman"
require "./plugins/hello_world"
require "./plugins/key_value_store"
require "./plugins/memo"
require "./plugins/password"
require "./plugins/programming_excuses"
require "./plugins/russian_roulette"
require "./plugins/what_the_commit"
require "./plugins/wiki"
require "./plugins/wti_status"

bot = Framework::Bot.create do
  config.from_file "settings.json"

  add_plugin Admin
  add_plugin CrystalEval
  add_plugin DiasporaVersion
  add_plugin GithubIssues
  add_plugin Hangman
  add_plugin HelloWorld
  add_plugin KeyValueStore
  add_plugin Memo
  add_plugin Password
  add_plugin ProgrammingExcuses
  add_plugin RussianRoulette
  add_plugin WhatTheCommit
  add_plugin Wiki
  add_plugin WtiStatus
end

bot.start
