require "./spec_helper"

describe SCTP::Server do
  describe "#initialize" do
    it "creates a server" do
      server = SCTP::Server.new("127.0.0.1", 0)
      server.should be_a(SCTP::Server)
      server.closed?.should be_false
      server.close
    end

    it "creates server with custom streams" do
      server = SCTP::Server.new("127.0.0.1", 0, streams: 10)
      server.should be_a(SCTP::Server)
      server.close
    end

    it "creates server on all interfaces" do
      server = SCTP::Server.new(0)
      server.should be_a(SCTP::Server)
      server.close
    end
  end

  describe "#accept" do
    it "accepts incoming connections" do
      server = SCTP::Server.new("127.0.0.1", 0)

      spawn do
        sleep 0.1
        if addr = server.local_address
          client = SCTP::Socket.new
          client.connect(addr.host, addr.port)
          client.write("Hello")
          client.close
        end
      end

      client = server.accept
      data = client.read_string(1024)
      data.should eq("Hello")
      client.close
      server.close
    end

    it "accepts with block" do
      server = SCTP::Server.new("127.0.0.1", 0)
      received = ""

      spawn do
        sleep 0.1
        if addr = server.local_address
          client = SCTP::Socket.new
          client.connect(addr.host, addr.port)
          client.write("Test")
          client.close
        end
      end

      server.accept do |client|
        received = client.read_string(1024)
      end

      received.should eq("Test")
      server.close
    end
  end

  describe "#close" do
    it "closes the server" do
      server = SCTP::Server.new("127.0.0.1", 0)
      server.close
      server.closed?.should be_true
    end
  end

  describe "#local_address" do
    it "returns local address" do
      server = SCTP::Server.new("127.0.0.1", 0)
      addr = server.local_address
      addr.should_not be_nil
      addr.not_nil!.host.should eq("127.0.0.1")
      server.close
    end
  end
end
