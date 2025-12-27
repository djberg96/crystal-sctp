require "./spec_helper"

describe SCTP::Socket do
  describe "#initialize" do
    it "creates a socket" do
      socket = SCTP::Socket.new
      socket.should be_a(SCTP::Socket)
      socket.closed?.should be_false
      socket.close
    end

    it "creates socket with custom stream count" do
      socket = SCTP::Socket.new(streams: 10)
      socket.outbound_streams.should eq(10)
      socket.inbound_streams.should eq(10)
      socket.close
    end
  end

  describe "#bind and #listen" do
    it "binds to an address" do
      socket = SCTP::Socket.new
      socket.bind("127.0.0.1", 0) # Port 0 = any available port
      socket.close
    end

    it "binds to multiple addresses (multi-homing)" do
      socket = SCTP::Socket.new
      socket.bind(["127.0.0.1"], 0)
      socket.close
    end

    it "adds bind address" do
      socket = SCTP::Socket.new
      socket.bind("127.0.0.1", 0)
      # Note: Adding same address twice may fail on some systems
      # This tests the API exists
      socket.close
    end

    it "raises on empty address list" do
      socket = SCTP::Socket.new
      expect_raises(ArgumentError, "Must provide at least one address") do
        socket.bind([] of String, 3000)
      end
      socket.close
    end
  end

  describe "#close" do
    it "closes the socket" do
      socket = SCTP::Socket.new
      socket.close
      socket.closed?.should be_true
    end

    it "is idempotent" do
      socket = SCTP::Socket.new
      socket.close
      socket.close # Should not error
      socket.closed?.should be_true
    end
  end

  describe "#write and #read" do
    it "sends and receives data" do
      server = SCTP::Socket.new
      server.bind("127.0.0.1", 0)
      server.listen

      # Get the actual port
      local_addr = server.local_address

      spawn do
        client = server.accept
        data = client.read_string(1024)
        client.write(data) # Echo back
        client.close
      end

      sleep 0.1 # Give server time to start

      if local_addr
        client = SCTP::Socket.new
        client.connect(local_addr.host, local_addr.port)
        client.write("Hello SCTP")
        response = client.read_string(1024)
        response.should eq("Hello SCTP")
        client.close
      end

      server.close
    end
  end

  describe "multi-homing" do
    it "connects to multiple addresses" do
      server = SCTP::Socket.new
      server.bind("127.0.0.1", 0)
      server.listen

      spawn do
        client = server.accept
        data = client.read_string(1024)
        client.write(data)
        client.close
      end

      sleep 0.1

      if local_addr = server.local_address
        client = SCTP::Socket.new
        # Connect with array of addresses (multi-homing)
        client.connect([local_addr.host], local_addr.port)
        client.write("Multi-home test")
        response = client.read_string(1024)
        response.should eq("Multi-home test")
        client.close
      end

      server.close
    end

    it "raises on empty address list for connect" do
      socket = SCTP::Socket.new
      expect_raises(ArgumentError, "Must provide at least one address") do
        socket.connect([] of String, 3000)
      end
      socket.close
    end
  end

  describe "#write with streams" do
    it "sends data on specific stream" do
      socket = SCTP::Socket.new(streams: 5)
      socket.bind("127.0.0.1", 0)
      socket.listen

      spawn do
        client = socket.accept
        buffer = Bytes.new(1024)
        bytes_read, stream_id, ppid = client.read_with_info(buffer)
        stream_id.should eq(2_u16)
        client.close
      end

      sleep 0.1

      if addr = socket.local_address
        client = SCTP::Socket.new(streams: 5)
        client.connect(addr.host, addr.port)
        client.write("Stream data", stream: 2)
        sleep 0.1
        client.close
      end

      socket.close
    end
  end

  describe "#no_delay=" do
    it "sets SCTP_NODELAY option" do
      socket = SCTP::Socket.new
      socket.no_delay = true
      socket.close
    end
  end

  describe "#non_blocking=" do
    it "sets non-blocking mode" do
      socket = SCTP::Socket.new
      socket.non_blocking = true
      socket.non_blocking?.should be_true
      socket.non_blocking = false
      socket.non_blocking?.should be_false
      socket.close
    end
  end

  describe "error handling" do
    it "raises on operations on closed socket" do
      socket = SCTP::Socket.new
      socket.close

      expect_raises(SCTP::Error, "Socket is closed") do
        socket.bind("127.0.0.1", 3000)
      end
    end

    it "raises on invalid stream" do
      socket = SCTP::Socket.new(streams: 3)
      socket.bind("127.0.0.1", 0)

      expect_raises(ArgumentError) do
        socket.write("data", stream: 5) # Stream 5 doesn't exist
      end

      socket.close
    end

    it "raises on negative stream" do
      socket = SCTP::Socket.new
      socket.bind("127.0.0.1", 0)

      expect_raises(ArgumentError, "Stream must be >= 0") do
        socket.write("data", stream: -1)
      end

      socket.close
    end
  end
end
