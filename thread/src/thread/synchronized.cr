class Synchronized(T)
  def initialize(@target : T)
    @mutex = Mutex.new
  end

  macro method_missing(name, args, block)
    @mutex.synchronize do
      @target.{{name.id}}({{*args}}) {{block}}
    end
  end
end
