class OpenSSL::SSL::Socket
  def closed?
    @bio.io.closed?
  end
end
