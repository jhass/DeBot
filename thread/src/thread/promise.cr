require "./monitor"

class Promise(T)
  class Future(T)
    include Monitor

    protected def initialize
      @fulfilled = false
      @callbacks = [] of T ->
    end

    protected def value= value : T
      synchronize do
        raise ArgumentError, "Already fulfilled" if @fulfilled
        @value = value
        @fulfilled = true
      end

      @callbacks.each &.call(value)
    end

    def value
      synchronize do
        until @fulfilled
          wait
        end

        @value
      end
    end

    def on_completion &callback
      @callbacks << callback
    end

    def value!
      value.not_nil!
    end
  end

  getter future

  def initialize
    @future = Future(T).new
  end

  def value= value : T
    @future.value = value
  end
end
