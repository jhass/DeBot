class Wiki
  include Cinch::Plugin

  WIKIS = {}
  %w[#diaspora #diaspora-de #diaspora-dev].each do |channel|
    WIKIS[channel] = "https://wiki.diasporafoundation.org/"
  end

  match /wiki\s+(.+)/

  def execute(m, title)
    return unless WIKIS.keys.include? m.channel.name
    title = title.squeeze(' ').strip.tr(' ', '_').capitalize
    m.reply "#{WIKIS[m.channel.name]}#{title}"
  end
end
