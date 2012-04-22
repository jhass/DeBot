module Cinch
  module Plugins
    class DownForEveryone
      match /(?:up|down)\?? (.+)/
    end
  end
end
