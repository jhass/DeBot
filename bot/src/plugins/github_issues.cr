require "framework/plugin"

class GithubIssues
  include Framework::Plugin

  PATTERN = /(?:^|\s+|\()#(\d{3,5})\b/

  config({
    repositories: {type: Hash(String, String), default: {} of String => String}
  })

  match PATTERN
  def execute msg, _match
    return unless msg.channel?
    return unless config.repositories.has_key? msg.channel.name
    issues = msg.message.scan(PATTERN)
    msg.reply issues.map {|issue| "https://github.com/#{config.repositories[msg.channel.name]}/issues/#{issue[1]}" }.join(" | ")
  end
end
