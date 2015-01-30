lib LibPThread
  fun set_name = pthread_setname_np(thread : Thread, name : UInt8*) : Int32
end

class Thread
  def name=(name : String)
    raise ArgumentError.new "Thread name must be 15 characters or less" if name.size > 15
    LibPThread.set_name(@th, name)
  end
end
