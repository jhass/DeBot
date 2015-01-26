require "./monitor"

class Queue(T)
  include Monitor

  def initialize
    @items = Array(T).new
  end

  def pop
    synchronize do
      while @items.empty?
        wait
      end

      @items.pop
    end
  end

  def shift
    synchronize do
      while @items.empty?
        wait
      end

      @items.shift
    end
  end

  def << item : T
    synchronize do
      @items << item
      signal
    end
  end

  def unshift item : T
    synchronize do
      @items.unshift item
      signal
    end
  end
end
