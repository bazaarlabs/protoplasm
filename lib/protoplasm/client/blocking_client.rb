require 'socket'

module Protoplasm
  class BlockingClient
    def self.for_types(types)
      cls = Class.new(self)
      cls.class_eval do
        (class << self; self; end).send(:define_method, :_types) { types }
      end
      cls
    end

    def close
      _socket.close if _socket && !_socket.closed?
    end

    def self.client(*args)
      client = new(*args)
      begin
        yield client
      ensure
        client.close
      end
    end

    private
    def host_port
      raise "Must be implemented by the client class"
    end

    def _socket(timeout = 5)
      count = 0
      begin
        host, port = host_port
        @socket ||= begin
          addr = Socket.getaddrinfo(host, nil)
          sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

          if timeout
            secs = Integer(timeout)
            usecs = Integer((timeout - secs) * 1_000_000)
            optval = [secs, usecs].pack("l_2")
            begin
              io.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
              io.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
            rescue Exception => ex
              # Solaris, for one, does not like/support socket timeouts.
              @logger.info "[memcache-client] Unable to use raw socket timeouts: #{ex.class.name}: #{ex.message}" if @logger
            end
          end
          sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
          sock
        end
        yield @socket if block_given?
      rescue Errno::EPIPE, Errno::ECONNRESET
        count += 1
        if count > 3
          raise
        else
          @socket = nil
          retry
        end
      end
    end

    def send_request(field, *args, &blk)
      s = ''
      type = self.class._types.request_type_for_field(field)
      cmd_class = type.command_class.fields.values.find{|f| f.name == field}
      cmd = self.class._types.request_class.new(self.class._types.request_type_field => type.type, type.field => cmd_class.type.new(*args))
      cmd.encode(s)
      obj = nil
      _socket do |socket|
        socket.write([Types::Request::NORMAL, s.size].pack("CQ"))
        socket.write s
        socket.flush
        fetch_objects = true
        while fetch_objects
          response_byte = socket.sysread(1)
          response_code = response_byte.unpack("C").first
          case response_code
          when Types::Response::NORMAL
            fetch_objects = !type.void?
            if fetch_objects
              len_buf = socket.sysread(8)
              len = len_buf.unpack("Q").first
              data = ''
              while data.size < len
                data << socket.sysread([len - data.size, 4096].min)
              end
              obj = type.response_class.decode(data.force_encoding('BINARY'))
              yield obj if block_given?
            end
            fetch_objects = false unless type.streaming?
          when Types::Response::STOP_STREAMING
            fetch_objects = false
          else
            raise "Control byte is #{response_byte.inspect}, code is #{response_code.inspect}"
          end
        end
      end
      obj
    rescue EOFError
      @socket = nil
    end
  end
end
