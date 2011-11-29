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
      @_socket ||= TCPSocket.open(host, port)
    end

    def send_request(field, *args, &blk)
      s = ''
      type = self.class._types.request_type_for_field(field)
      cmd_class = type.command_class.fields.values.find{|f| f.name == field}
      cmd = self.class._types.request_class.new(self.class._types.request_type_field => type.type, type.field => cmd_class.type.new(*args))
      cmd.encode(s)
      socket = _socket
      socket.write([0, s.size].pack("CQ"))
      socket.write s
      socket.flush
      fetch_objects = true
      obj = nil
      while fetch_objects
        response_code = socket.readpartial(1).unpack("C").first
        case response_code
        when Types::Response::NORMAL
          fetch_objects = !type.void?
          if fetch_objects
            len_buf = ''
            socket.readpartial(8 - len_buf.size, len_buf) while len_buf.size != 8
            len = len_buf.unpack("Q").first
            buf = ''
            socket.readpartial(len - buf.size, buf) until buf.size == len
            obj = type.response_class.decode(buf)
            yield obj if block_given?
          end
          fetch_objects = false unless type.streaming?
        when Types::Response::STOP_STREAMING
          fetch_objects = false
        end
      end
      obj
    end
  end
end
