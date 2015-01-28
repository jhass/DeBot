require "openssl"

require "./socket"

@[Link("ssl")]
lib LibSSL
  SSL_ERROR_NONE             = 0
  SSL_ERROR_SSL              = 1
  SSL_ERROR_WANT_READ        = 2
  SSL_ERROR_WANT_WRITE       = 3
  SSL_ERROR_WANT_X509_LOOKUP = 4
  SSL_ERROR_SYSCALL          = 5
  SSL_ERROR_ZERO_RETURN      = 6
  SSL_ERROR_WANT_CONNECT     = 7
  SSL_ERROR_WANT_ACCEPT      = 8

  fun ssl_get_error = SSL_get_error(handle : SSL, ret : Int32) : Int32
  fun get_error = ERR_get_error() : UInt64
  fun error_string = ERR_error_string(code : UInt64, buf : Void*) : UInt8*
  fun ssl_load_error_strings = SSL_load_error_strings()
end

module IO
  alias FdIOs = FileDescriptorIO|OpenSSL::SSL::Socket
end

module OpenSSL
  class SSLError < Exception
  end
end

LibSSL.ssl_load_error_strings

class OpenSSL::SSL::Socket
  include IO

  def initialize(@io, mode = :client, context = Context.default)
    @ssl = LibSSL.ssl_new(context)
    @bio = BIO.new(io)
    LibSSL.ssl_set_bio(@ssl, @bio, @bio)

    if mode == :client
      ret = LibSSL.ssl_connect(@ssl)
    else
      ret = LibSSL.ssl_accept(@ssl)
    end

    if ret < 1
      case LibSSL.ssl_get_error(@ssl, ret)
      when LibSSL::SSL_ERROR_SSL
        raise_error
      end
    end
  end

  def fd
    @io.not_nil!.fd
  end

  def read(slice : Slice(UInt8), count)
    ret = LibSSL.ssl_read(@ssl, slice.pointer(count), count)
    if ret < 1
      case LibSSL.ssl_get_error(@ssl, ret)
      when LibSSL::SSL_ERROR_SSL
        raise_error
      when LibSSL::SSL_ERROR_WANT_READ
        return read(slice)
      end
    end

    ret
  end

  def write(slice : Slice(UInt8), count)
    ret = LibSSL.ssl_write(@ssl, slice.pointer(count), count)
    if ret < 1
      case LibSSL.ssl_get_error(@ssl, ret)
      when LibSSL::SSL_ERROR_SSL
        raise_error
      when LibSSL::SSL_ERROR_WANT_WRITE
        return write(slice)
      end
    end

    ret
  end

  private def raise_error
    raise SSLError.new String.new(LibSSL.error_string(LibSSL.get_error, nil))
  end
end
