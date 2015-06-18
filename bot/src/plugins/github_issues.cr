require "framework/plugin"
require "http/client"
require "json"

class GithubIssues
  include Framework::Plugin

  class Issue
    json_mapping({
        html_url: String,
        title: String
    })

    def to_s(io)
      io << html_url << " (#{title})"
    end
  end


  PATTERN = /(?:^|\s+|\()#(\d{3,5})\b/

  config({
    repositories: {type: Hash(String, String), default: {} of String => String}
  })

  match PATTERN
  def execute msg, _match
    return unless msg.channel?
    return unless config.repositories.has_key? msg.channel.name
    issues = msg.message.scan(PATTERN)
    msg.reply issues.map {|issue| fetch_issue config.repositories[msg.channel.name], issue[1]}.compact.join(" | ")
  end

  private def fetch_issue repo, issue_id
    api_response = HTTP::Client.get("https://api.github.com/repos/#{repo}/issues/#{issue_id}",
      headers: HTTP::Headers{"Accept" => ["application/vnd.github.v3+json"], "User-Agent" => ["CeBot"]})
    if api_response.status_code == 200
      Issue.from_json api_response.body
    end
  end
end
