class String
  def partition(delim)
    delim = delim.to_s
    return {"", "", clone} if delim == ""
    position = index(delim)
    return {clone, "", ""} unless position
    {self[0, position], delim.clone, self[(position+delim.length)..-1]}
  end

  def match(regex : Regex)
    regex.match self
  end

  def [](regex : Regex, group)
    match = match(regex)
    match ? match[group] : ""
  end

  def [](regex : Regex)
    self[regex, 0]
  end

  def delete(regex : Regex)
    gsub(regex, "")
  end

  def squeeze(*whitelist)
    String.build do |string|
      previous = nil
      each_char do |char|
        if whitelist.empty? || !(char.in_character_specs?(*whitelist) && char == previous)
          string << char
        end
        previous = char
      end
    end
  end

end

struct Char
  def in_character_specs?(*specs)
    specs.all? {|spec|
      in_character_spec?(spec)
    }
  end

  private def in_character_spec?(spec)
    positive = true
    range = false
    last = nil

    spec.each_char do |char|
      case char
      when '^'
        unless last # beginning of spec
          positive = false
          last = char
          next
        end
      when '-'
        if last && last != '\\' && (!positive && last != '^')
          range = true
          next
        else # at the beginning of the spec or ^- at the beginning
          return true if self == char
        end
      end

      if range && last
        raise ArgumentError.new "Invalid range" if last > self
        return positive if last <= self <= char
        range = false
      elsif char != '\\'
        return positive if self == char
      end

      last = char
    end

    return positive if (last == '\\' || last == '-') && self == last

    !positive
  end
end
