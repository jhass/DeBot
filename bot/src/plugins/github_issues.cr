require "framework/plugin"

class GithubIssues
  include Framework::Plugin

  PATTERN = /(?:^|\s+|\()#(\d{3,5})\b/

  def initialize @projects : Hash(String, String)
  end

  match PATTERN
  def execute msg, _match
    return unless msg.channel?
    return unless @projects.has_key? msg.channel.name
    issues = msg.message.scan(PATTERN)
    msg.reply issues.map {|issue| "https://github.com/#{@projects[msg.channel.name]}/issues/#{issue[1]}" }.join(" | ")
  end
end
