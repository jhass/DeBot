module Framework
  class Timer
    def initialize delay, limit=nil, &block
      spawn do
        runs = 0
        loop do
          sleep delay
          block.call
          runs += 1
          break if limit && runs >= limit
        end
      end
    end
  end
end
