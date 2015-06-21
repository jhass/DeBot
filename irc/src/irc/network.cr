module IRC
  class Network
    NONE = new

    property? account_notify
    property? extended_join

    def initialize
      @account_notify = false
      @extended_join  = false
    end
  end
end
