# Protoplasm

Protoplasm makes is easy to define an RPC server/client which is backed by protobuf through Beefcake.

## Defining your service endpoints

The current service model is very simple. You can send only one type of protobuf object (the request object). This object must have an enum and a series of optional command fields to allow it to send commands. Here is an example of how to create a request object type:

```ruby
class Command
  include Beefcake::Message
  module Type
    PING   = 1
    UPCASE = 2
  end
  required :type,           Type,          1
  optional :ping_command,   PingCommand,   2
  optional :upcase_command, UpcaseCommand, 3
end
```

In this case, your request object would be able to accept one, and only one subcommand object. Those types are `PingCommand`, `UpcaseCommand` and `EvenCommand`.

So, in order to mark this `Command` class as your request class, you'd do the following:

```ruby
module Types
  include Protoplasm::Types
  
  # .. your actual classes would go here

  request_class Command
  request_type_field :type
end
```

## Defining your response objects

Every subcommand can choose to relay back no objects, one object, or stream any number of objects. Those objects must all be of the same type.

To define which objects you expect back, you must add the following.

```ruby
module Types
  rpc_map Command::Type::PING,   :ping_command,   nil
  rpc_map Command::Type::UPCASE, :upcase_command, UpcaseResponse
  rpc_map Command::Type::EVEN,   :even_command,   EvenResponse,  :streaming => true
```

In this case, this would define the ping command as returning no object, the upcase command returns a single object, of type `UpcaseResponse`, and the even command return any number of `EvenResponse` objects.

## Server implementation

Currently there is a single server implementation `EMServer`, which defines a non-blocking EventMachine based server. To create an `EMServer`, you subclass `Protoplasm::EMServer` and setup handlers for each of your command types. For example, a worker server could look like this:

```ruby
class Server < Protoplasm::EMServer
  def process_ping_command(ping_command)
    # do nothing
  end

  def process_upcase_command(upcase_command)
    send_response(:response => cmd.word.upcase)
  end

  def process_even_command(even_command)
    (1..even_command.top).each do |num|
      send_response(:num => num) if num % 2 == 0
    end
    finish_streaming
  end
end
```

This server then could be started with `Server.start(3000)` which would start on port 3000 and process requests.

## Client

Currently there is a single client implementation: `BlockingClient`. It defines a blocking `TCPSocket` based client. To create a client for this example, you would do the following.

```ruby
class Client < Protoplasm::BlockingClient
  def initialize(host, port)
    super(Types, host, port)
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
end
```

Look at the full example under `test/test_helper.rb`.