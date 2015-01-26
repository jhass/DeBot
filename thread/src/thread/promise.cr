require "./monitor"

class Promise(T)
  include Monitor

  def initialize
    @fulfilled = false
  end

  def value= value : T
    synchronize do
      raise ArgumentError, "Already fulfilled" if @fulfilled
      @value = value
      @fulfilled = true
    end
  end

  def value
    synchronize do
      until @fulfilled
        wait
      end

      @value
    end
  end

  def value!
    value.not_nil!
  end
end
