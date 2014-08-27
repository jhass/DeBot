class Issues
  include Cinch::Plugin

  PROJECTS = { '#diaspora-dev' => 'https://github.com/diaspora/diaspora/issues/' }

  listen_to :channel
  def listen(m)
    return unless PROJECTS.has_key? m.channel.name
    issues = m.message.scan(/(?:^|\s+|\()#(\d{4,5})\b/).map(&:first)
    return if issues.empty?
    m.reply issues.map {|issue| "#{PROJECTS[m.channel.name]}#{issue}" }.join(' | ')
  end
end
