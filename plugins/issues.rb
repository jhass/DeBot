class Issues
  include Cinch::Plugin

  PROJECTS = { '#diaspora-dev' => 'https://github.com/diaspora/diaspora/issues/' }

  match /(?:^|\s+)#(\d{4,5})(?:\s+|$)/, prefix: nil
  def execute(m, issue)
    return unless PROJECTS.has_key? m.channel.name
    m.reply "#{PROJECTS[m.channel.name]}#{issue}"
  end
end
