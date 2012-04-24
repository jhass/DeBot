require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'yaml'

class TranslationStatus
  include Cinch::Plugin

  API_KEY = "66c5e5731ada866d7a0be466f4fc4fb0abb22e76"
  PROJECT = "3020-Diaspora"

  set(plugin_name: "transstats",
      help: "Usage: !ts code -Get statistics about code at #{PROJECT.split('-').last} on WebTranslateIt")

  match /(?:ts|trans(?:lation)?stati?s(?:tics)?) ([a-z0-9_-]+)/

  def execute(m, code)
    code.gsub!("_", "-")
    url = "https://webtranslateit.com/api/projects/#{API_KEY}/stats.yaml"
    content = open(url).read
    stats = YAML.load content

    if code == "en"
      m.reply "English is the master translation ;)"
    elsif stats.keys.include?(code)
      stats = stats[code]
      if stats['count_strings_done'] == stats['count_strings']
        m.reply  "The translation for #{code} is complete :)."
      else
        m.reply "The translation for #{code} has #{stats['count_strings_done']}/#{stats['count_strings']} keys done, with #{stats['count_strings_to_translate']} untranslated and #{stats['count_strings_to_proofread']} to proofread."
      end
      m.reply " Join the team at https://webtranslateit.com/en/projects/#{PROJECT} to further improve it!"
    else
      m.reply  "There so no translation for #{code} yet. Have a look at https://github.com/liamnic/IntrestIn/wiki/How-to-contribute-translations on how to create it!"
    end
  end
end
