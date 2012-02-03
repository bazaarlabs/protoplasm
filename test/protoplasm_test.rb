require File.expand_path('../test_helper', __FILE__)

describe "Protoplasm test server" do
  it "should ping" do
    with_proto_server(ProtoplasmTest::EMServer) do |port|
      client = ProtoplasmTest::Client.new('127.0.0.1', port)
      client.ping
      pass
    end
  end

  it "should upcase" do
    with_proto_server(ProtoplasmTest::EMServer) do |port|
      client = ProtoplasmTest::Client.new('127.0.0.1', port)
      assert_equal "LOWER", client.upcase('lower')
    end
  end

  it "should give you even numbers" do
    with_proto_server(ProtoplasmTest::EMServer) do |port|
      client = ProtoplasmTest::Client.new('127.0.0.1', port)
      nums = []
      client.evens(10) do |resp|
        nums << resp
      end
      assert_equal [2, 4, 6, 8], nums
    end
  end

  it "should allow multiple calls" do
    with_proto_server(ProtoplasmTest::EMServer) do |port|
      client = ProtoplasmTest::Client.new('127.0.0.1', port)
      client.ping
      assert_equal "LOWER", client.upcase('lower')
      assert_equal "UPPER", client.upcase('upper')
      nums = []
      client.evens(10) do |resp|
        nums << resp
      end
      assert_equal [2, 4, 6, 8], nums
      client.ping
      assert_equal "LOWER", client.upcase('lower')
    end
  end

  it "should allow a self closing client" do
    with_proto_server(ProtoplasmTest::EMServer) do |port|
      ProtoplasmTest::Client.client('127.0.0.1', port) do |client|
        client.ping
        assert_equal "LOWER", client.upcase('lower')
        assert_equal "UPPER", client.upcase('upper')
        nums = []
        client.evens(10) do |resp|
          nums << resp
        end
        assert_equal [2, 4, 6, 8], nums
        client.ping
        assert_equal "LOWER", client.upcase('lower')
      end
    end
  end
  it "should do constant lookups" do
    assert_equal :PING, ProtoplasmTest::Types::Command::Type.lookup(1)
    assert_equal :UPCASE, ProtoplasmTest::Types::Command::Type.lookup(2)
    assert_equal :EVEN, ProtoplasmTest::Types::Command::Type.lookup(3)
  end
end