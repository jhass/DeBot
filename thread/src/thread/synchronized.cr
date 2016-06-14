class Synchronized(T)
  def initialize(@target : T)
    @mutex = Mutex.new
  end

  macro method_missing(call)
    @mutex.synchronize do
      @target.{{call}}
    end
  end
end
