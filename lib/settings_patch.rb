require 'modalsettings'
require 'yaml'

class Settings < OpenStruct
  attr_accessor :source

  def self.load(filename, root=nil)
    s = self[YAML.load_file "settings.yml"]
    s.source = filename
    s
  end

  def save!
    open(@source, "w") do |io|
      io.write self.to_yaml
    end
  end

  def setup!
    self[:identify] = self[:identify].merge("type"  => self[:identify]["type"].to_sym) if self[:identify] && self[:identify]["type"]
  end

  def has_key?(key)
    @table.has_key?(key)
  end

  def keys
    @table.keys
  end

  def select(&block)
    @table.select(&block)
  end

  alias_method :delete, :delete_field
end

def settings
  $settings ||= Settings.load "settings.yml"
end

settings.setup!
