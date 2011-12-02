require 'beefcake'

module Protoplasm
  module Types
    module ConstLookup
      def self.included(o)
        o.extend(ClassMethods)
      end

      module ClassMethods
        def lookup(val)
          enum_map[val]
        end

        def enum_map
          @enum_map ||= begin
            constants.inject({}) { |h,k| h[const_get(k)] = k.to_sym; h }
          end
        end
      end
    end

    module Request
      NORMAL = 0
    end

    module Response
      NORMAL         = 0
      STOP_STREAMING = 10
    end

    def self.included(cls)
      cls.extend(ClassMethods)
    end

    class RequestResponseType < Struct.new(:request_class, :response_class, :type, :field, :streaming)

      alias_method :streaming?, :streaming

      def command_class
        request_class
      end

      def void?
        response_class.nil?
      end
    end

    module ClassMethods
      def request_class(request_class = nil)
        request_class ? @request_class = request_class : @request_class
      end

      def request_type(request_obj)
        request_obj.send(@request_type_field)
      end

      def request_type_field(field = nil)
        field ? @request_type_field = field : @request_type_field
      end

      def rpc_map(type, field, response_class, opts = nil)
        @response_map_by_field ||= {}
        @response_map_by_type ||= {}
        streaming = opts && opts.key?(:streaming) ? opts[:streaming] : false
        rrt = RequestResponseType.new(@request_class, response_class, type, field, streaming)
        @response_map_by_field[field] = rrt
        @response_map_by_type[type] = rrt
      end

      def request_type_for_field(field)
        @response_map_by_field[field]
      end

      def request_type_for_request(req)
        @response_map_by_type[req.send(@request_type_field)]
      end
    end
  end
end
