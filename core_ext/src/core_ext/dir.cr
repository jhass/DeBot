lib C
  fun chdir = chdir(path : UInt8*) : Int32
end

class Dir
  def self.chdir path : String
    C.chdir path
  end
end
