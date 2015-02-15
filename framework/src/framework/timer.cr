def safe_sleep delay
  start = Time.now
  elapsed = 0
  begin
    sleep delay-elapsed
  rescue e : Errno
    puts "In safe sleep:"
    pp e.message
    pp e.errno
    raise e
  ensure
    elapsed = start-Time.now
  end while elapsed < delay
end

module Framework
  class Timer
    def initialize delay, limit=nil, &block
      @th = Thread.new(self) do |timer|
        runs = 0
        loop do
          safe_sleep delay
          block.call
          runs += 1
          break if limit && runs >= limit
        end
      end
    end
  end
end
