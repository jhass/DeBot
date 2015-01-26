class Array(T)
  def to_h
    self.class.to_h(self)
  end

  def self.to_h array : Array({K, V})
    array.each_with_object(Hash(K, V).new) do |item, hash|
      hash[item[0]] = item[1]
    end
  end

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
