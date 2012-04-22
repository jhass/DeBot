require 'settingslogic'
require 'yaml'

class Settingslogic
  def save!
    hash = {}.merge(self)
    open(self.class.source, "w") do |io|
      io.write YAML.dump hash
    end
  end
end

class Settings < Settingslogic
  source "settings.yml"
  
  def self.setup!
    self[:identify] = self[:identify].merge("type"  => self[:identify]["type"].to_sym) if self[:identify] && self[:identify]["type"]
  end
end
