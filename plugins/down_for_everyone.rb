module Cinch
  module Plugins
    class DownForEveryone
      set(plugin_name: "up",
          help: "Usage: !up/!down example.org")

      match /(?:up|down)\??\s+(.+)/
    end
  end
end
