require "./spec_helper"

describe SCTP::Stream do
  describe "#initialize" do
    it "creates a stream" do
      socket = SCTP::Socket.new(streams: 5)
      stream = SCTP::Stream.new(socket, 2)
      stream.id.should eq(2)
      socket.close
    end

    it "raises on negative stream ID" do
      socket = SCTP::Socket.new(streams: 5)
      expect_raises(ArgumentError, "Invalid stream ID") do
        SCTP::Stream.new(socket, -1)
      end
      socket.close
    end

    it "raises on stream ID exceeding available streams" do
      socket = SCTP::Socket.new(streams: 3)
      expect_raises(ArgumentError, /exceeds available streams/) do
        SCTP::Stream.new(socket, 5)
      end
      socket.close
    end
  end

  describe "#write" do
    it "writes to the stream" do
      server = SCTP::Socket.new(streams: 5)
      server.bind("127.0.0.1", 0)
      server.listen

      spawn do
        client = server.accept
        buffer = Bytes.new(1024)
        bytes_read, stream_id, ppid = client.read_with_info(buffer)
        stream_id.should eq(3_u16)
        client.close
      end

      sleep 0.1

      if addr = server.local_address
        client = SCTP::Socket.new(streams: 5)
        client.connect(addr.host, addr.port)

        stream = SCTP::Stream.new(client, 3)
        stream.write("Stream data")

        sleep 0.1
        client.close
      end

      server.close
    end
  end
end

describe SCTP::StreamInfo do
  describe "#initialize" do
    it "creates stream info" do
      info = SCTP::StreamInfo.new(1_u16, 0_u32, false)
      info.stream_id.should eq(1_u16)
      info.ppid.should eq(0_u32)
      info.unordered.should be_false
    end

    it "creates with default values" do
      info = SCTP::StreamInfo.new(2_u16)
      info.stream_id.should eq(2_u16)
      info.ppid.should eq(0_u32)
      info.unordered.should be_false
    end
  end
end
