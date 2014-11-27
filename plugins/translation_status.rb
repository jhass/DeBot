require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'yaml'

class TranslationStatus
  include Cinch::Plugin

  PROJECTS = {
    'diaspora' => {
      api_key: "66c5e5731ada866d7a0be466f4fc4fb0abb22e76",
      slug: "3020-Diaspora"
    },
    'website' => {
      api_key: "2h1Yw5ZUkdxf1Kx3vImONA",
      slug: "7017-Website"
    },
    'jsxc' => {
      api_key: "yaL4zA7OuczXRau3JoeU4A",
      slug: "10365-JSXC"
    }
  }
  DEFAULT = 'diaspora'
  COMMAND = /(?:ts|trans(?:lation)?stati?s(?:tics)?)/
  CODE = /([a-zA-Z0-9_-]+)/

  set(plugin_name: "transstats",
      help: "Usage: !ts [project] code -Get statistics about code at project (Default=diaspora) on WebTranslateIt")

  match /#{COMMAND}\s+#{CODE}$/
  match /#{COMMAND}\s+(\w+)\s+#{CODE}/

  def execute(m, project=DEFAULT, code)
    code.gsub!("_", "-")

    if code == "en"
      m.reply "English is the master translation ;)"
      return
    end

    url = "https://webtranslateit.com/api/projects/#{PROJECTS[project][:api_key]}/stats.yaml"
    content = open(url, &:read)
    stats = YAML.load content

    if stats.keys.include?(code)
      stats = stats[code]
      if stats['count_strings_done'] == stats['count_strings']
        m.reply  "The translation for #{code} is complete :)."
      else
        m.reply "The translation for #{code} has #{stats['count_strings_done']}/#{stats['count_strings']} keys done, with #{stats['count_strings_to_translate']} untranslated, #{stats['count_strings_to_proofread']} to proofread and #{stats['count_strings_to_verify']} to verify."
      end
      m.reply " Join the team at https://webtranslateit.com/en/projects/#{PROJECTS[project][:slug]} to further improve it!"
    else
      m.reply  "There so no translation for #{code} yet. Have a look at https://wiki.diasporafoundation.org/Contribute_translations on how to create it!"
    end
  end
end
