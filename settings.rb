require 'settingslogic'

class Settings < Settingslogic
  source "settings.yml"
  
  def self.setup!
    self[:identify] = self[:identify].merge("type"  => self[:identify]["type"].to_sym) if self[:identify] && self[:identify]["type"]
  end
end
