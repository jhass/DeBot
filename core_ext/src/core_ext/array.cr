class Array(T)
  def partition
    left = Array(T).new
    right = Array(T).new
    each do |item|
      if yield item
        left << item
      else
        right << item
      end
    end
    {left, right}
  end
end
