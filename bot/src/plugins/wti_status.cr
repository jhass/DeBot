require "http/client"
require "json"

require "framework/plugin"

class WtiStatus
  class Stats
    json_mapping({
      count_strings_done: Int32,
      count_strings: Int32,
      count_strings_to_translate: Int32,
      count_strings_to_proofread: Int32,
      count_strings_to_verify: Int32
    })
  end

  class Project
    json_mapping({
      api_key: String,
      slug: String
    })
  end

  include Framework::Plugin

  config({
    projects: {type: Hash(String, Project), default: {} of String => Project},
    default_project: {type: String, default: "configure_me"}
  })

  # command (?:ts|trans(?:lation)?stati?s(?:tics)?)
  # code ([a-zA-Z0-9_-]+)
  match /^!(?:ts|trans(?:lation)?stati?s(?:tics)?)\s+([a-zA-Z0-9_-]+)$/
  match /^!(?:ts|trans(?:lation)?stati?s(?:tics)?)\s+(\w+)\s+([a-zA-Z0-9_-]+)/

  def execute msg, match
    project = match.size == 2 ? match[1] : config.default_project
    code = match.size == 2 ? match[2] : match[1]
    code = code.tr("_", "-")

    if code == "en"
      msg.reply "English is the master translation ;)"
      return
    end

    unless config.projects.has_key? project
      msg.reply "#{msg.sender.nick}: Unconfigured project #{project}."
      return
    end

    url = "https://webtranslateit.com/api/projects/#{config.projects[project].api_key}/stats.json"
    content = HTTP::Client.get(url).body
    stats = Hash(String, Stats).from_json content

    if stats.has_key?(code)
      stats = stats[code]
      if stats.count_strings_done == stats.count_strings
        msg.reply  "The translation for #{code} is complete :)."
      else
        msg.reply "The translation for #{code} has #{stats.count_strings_done}/#{stats.count_strings} keys done, with #{stats.count_strings_to_translate} untranslated, #{stats.count_strings_to_proofread} to proofread and #{stats.count_strings_to_verify} to verify."
      end
      msg.reply " Join the team at https://webtranslateit.com/en/projects/#{config.projects[project].slug} to further improve it!"
    else
      msg.reply  "There so no translation for #{code} yet. Have a look at https://wiki.diasporafoundation.org/Contribute_translations on how to create it!"
    end
  end
end
