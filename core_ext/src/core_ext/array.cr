class Array(T)
  def to_h
    each_with_object(Hash(typeof(first[0]), typeof(first[1])).new) do |item, hash|
      hash[item[0]] = item[1]
    end
  end
end
