class Array(T)
  def to_h
    self.class.to_h(self)
  end

  def self.to_h array : Array({K, V})
    array.each_with_object(Hash(K, V).new) do |item, hash|
      hash[item[0]] = item[1]
    end
  end
end
