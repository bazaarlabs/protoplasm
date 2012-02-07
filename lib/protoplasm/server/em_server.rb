require 'eventmachine'

module Protoplasm
  class EMServer < EventMachine::Connection
    def self.for_types(types)
      cls = Class.new(self)
      cls.class_eval do
        (class << self; self; end).send(:define_method, :_types) { types }
      end
      cls
    end


    def self.start(port)
      if EM.reactor_running?
        EM::start_server("0.0.0.0", port, self) do |srv|
          yield srv if block_given?
        end
      else
        begin
          EM.run do
            start(port)
          end
        rescue Interrupt
        end
      end
    end

    def post_init
      @_response_types = []
      @data = ''
    end

    def receive_data(data)
      @data << data
      data_ready
    end

    def finish_streaming
      @_response_types.shift
      send_data [Types::Response::STOP_STREAMING].pack("C")
    end

    def send_void
      @_response_types.shift
      send_data [Types::Response::NORMAL].pack("C")
    end

    def data_ready
      @control = @data.slice!(0, 1).unpack("C").first unless @control
      case @control
      when Types::Request::NORMAL
        @size = @data.slice!(0, 8).unpack("Q").first unless @size
        if @data.size >= @size
          buf = @data.slice!(0, @size)
          @size, @control = nil, nil
          obj = self.class._types.request_class.decode(buf)
          type = self.class._types.request_type_for_request(obj)
          @_response_types << type
          EM.next_tick do
            send(:"process_#{type.field}", obj.send(type.field))
          end
          data_ready unless @data.empty?
        end
      else
        # illegal char
        close_connection
      end
    end

    def send_response(*args)
      type = @_response_types.first
      @_response_types.shift unless type.streaming?
      obj = type.response_class.new(*args)
      s = ''
      obj.encode(s)
      send_data [Types::Response::NORMAL].pack("C")
      send_data [s.size].pack("Q")
      send_data s.force_encoding('BINARY')
    end
  end
end
