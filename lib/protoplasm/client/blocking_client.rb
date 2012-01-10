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

    private
    def host_port
      raise "Must be implemented by the client class"
    end

    def _socket
      host, port = host_port
      count = 0
      begin
        @socket ||= begin
          s = TCPSocket.open(host, port)
          s.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
          s
        end
        yield @socket
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
          response_byte = socket.read(1)
          response_code = response_byte.unpack("C").first
          case response_code
          when Types::Response::NORMAL
            fetch_objects = !type.void?
            if fetch_objects
              len_buf = socket.read(8)
              len = len_buf.unpack("Q").first
              data = socket.read(len)
              obj = type.response_class.decode(data)
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
    end
  end
end
