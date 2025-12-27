module SCTP
  # Represents information about an SCTP stream within an association
  struct StreamInfo
    getter stream_id : UInt16
    getter ppid : UInt32
    getter unordered : Bool

    def initialize(@stream_id : UInt16, @ppid : UInt32 = 0_u32, @unordered : Bool = false)
    end
  end

  # Represents an individual SCTP stream
  class Stream
    @socket : Socket
    @stream_id : Int32

    def initialize(@socket : Socket, @stream_id : Int32)
      raise ArgumentError.new("Invalid stream ID") if @stream_id < 0
      raise ArgumentError.new("Stream ID #{@stream_id} exceeds available streams") if @stream_id >= @socket.outbound_streams
    end

    # Write to this stream
    def write(data : String | Bytes, unordered : Bool = false, ppid : UInt32 = 0_u32) : Nil
      @socket.write(data, stream: @stream_id, unordered: unordered, ppid: ppid)
    end

    # Stream ID
    def id : Int32
      @stream_id
    end
  end
end
