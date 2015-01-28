module Framework
  class Timer
    def initialize delay, limit=nil, &block
      @th = Thread.new(self) do |timer|
        runs = 0
        loop do
          sleep delay
          block.call
          runs += 1
          break if runs >= limit
        end
      end
    end
  end
end
