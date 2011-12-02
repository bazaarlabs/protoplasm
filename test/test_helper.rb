require 'rubygems'
require 'minitest/autorun'
require 'protoplasm'
require 'timeout'

class ProtoplasmTest
  module Types
    include Protoplasm::Types

    class PingCommand
      include Beefcake::Message
    end

    class UpcaseCommand
      include Beefcake::Message
      required :word, :string, 1
    end

    class EvenCommand
      include Beefcake::Message
      required :top, :uint32, 1
    end

    class UpcaseResponse
      include Beefcake::Message
      required :response, :string, 1
    end

    class EvenResponse
      include Beefcake::Message
      required :num, :uint32, 1
    end

    class Command
      include Beefcake::Message
      module Type
        include Protoplasm::Types::ConstLookup
        PING   = 1
        UPCASE = 2
        EVEN   = 3
      end
      required :type,           Type,          1
      optional :ping_command,   PingCommand,   2
      optional :upcase_command, UpcaseCommand, 3
      optional :even_command,   EvenCommand,   4
    end

    request_class Command
    request_type_field :type
    rpc_map Command::Type::PING,   :ping_command,   nil
    rpc_map Command::Type::UPCASE, :upcase_command, UpcaseResponse
    rpc_map Command::Type::EVEN,   :even_command,   EvenResponse,  :streaming => true
  end

  class EMServer < Protoplasm::EMServer.for_types(Types)
    def process_upcase_command(cmd)
      send_response(:response => cmd.word.upcase)
    end

    def process_even_command(cmd)
      spit_out_even(1, cmd.top)
    end

    def process_ping_command(cmd)
      send_void
    end

    def spit_out_even(cur, top)
      EM.next_tick do
        if cur == top
          finish_streaming
        else
          if cur % 2 == 0
            send_response(:num => cur)
          end
          spit_out_even(cur + 1, top)
        end
      end
    end
  end

  class Client < Protoplasm::BlockingClient.for_types(Types)
    def initialize(host, port)
      @host, @port = host, port
    end

    def ping
      send_request(:ping_command)
    end

    def upcase(word)
      send_request(:upcase_command, :word => word).response
    end

    def evens(top)
      send_request(:even_command, :top => top) { |resp| yield resp.num }
    end

    def host_port
      [@host, @port]
    end
  end
end

class MiniTest::Spec
  def with_proto_server(cls)
    port = 19866
    pid = fork { cls.start(port) }
    begin
      Timeout.timeout(10.0) {
        begin
          TCPSocket.open("127.0.0.1", port).close
        rescue
          sleep(0.1)
          retry
        end
      }
      yield port
    ensure
      Process.kill("INT", pid) if pid
    end
  end
end