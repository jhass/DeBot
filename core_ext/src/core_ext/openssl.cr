class OpenSSL::SSL::Socket
  def closed?
    Box(IO).unbox(@bio.@boxed_io).closed?
  end
end
