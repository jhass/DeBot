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
end
