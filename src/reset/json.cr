module JSON
  class Error
    def self.new(*args)
      raise *args
    end
  end
end

class IO::Error
  def self.new(*args)
    raise *args
  end
end

module IO::Syscall
  private def wait_writable(timeout = @write_timeout)
  end

  private def wait_writable(timeout = @write_timeout)
    yield
  end

  def write_syscall_helper(slice : Bytes, errno_msg : String) : Nil
    return if slice.empty?

    begin
      loop do
        bytes_written = yield slice
        if bytes_written != -1
          slice += bytes_written
          return if slice.size == 0
        else
          if Errno.value == Errno::EAGAIN
            # FIXME
          else
            raise Errno.new(errno_msg)
          end
        end
      end
    end
  end
end

require "./json/*"
