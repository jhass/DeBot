class OpenSSL::SSL::Socket < IO
  def closed?
    @bio.io.closed?
  end
end
