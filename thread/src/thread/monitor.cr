require "./checking_mutex"
module Monitor
  def mutex
    @mutex ||= CheckingMutex.new
  end

  def condition
    @condition ||= ConditionVariable.new
  end

  def synchronize
    mutex.synchronize do |m|
      yield m
    end
  end

  def wait
    synchronize do |mutex|
      condition.wait mutex
    end
  end

  def signal
    condition.signal
  end

  macro synchronized_delegate(method, to_object)
    def {{method.id}}(*args)
      synchronize do
        {{to_object.id}}.{{method.id}}(*args)
      end
    end
  end
end
