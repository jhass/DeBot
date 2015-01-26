class String
  def partition(delim)
    delim = delim.to_s
    return {"", "", clone} if delim == ""
    position = index(delim)
    return {clone, "", ""} unless position
    {self[0, position], delim.clone, self[(position+delim.length)..-1]}
  end

  def match regex : Regex
    regex.match self
  end
end
