require "socket"

module SCTP
  # High-level SCTP server implementation (similar to TCPServer)
  #
  # Example:
  # ```
  # server = SCTP::Server.new("127.0.0.1", 3000)
  # loop do
  #   client = server.accept
  #   spawn do
  #     # Handle client
  #     client.close
  #   end
  # end
  # ```
  class Server
    @socket : Socket

    # Create and bind a new SCTP server
    def initialize(host : String, port : Int32, streams : Int32 = 1, backlog : Int32 = 128)
      @socket = Socket.new(streams: streams)
      @socket.bind(host, port)
      @socket.listen(backlog)
    end

    # Create server on all interfaces
    def self.new(port : Int32, streams : Int32 = 1, backlog : Int32 = 128)
      new("0.0.0.0", port, streams, backlog)
    end

    # Accept an incoming connection
    def accept : Socket
      @socket.accept
    end

    # Accept with a block
    def accept(&block : Socket -> _)
      client = accept
      begin
        yield client
      ensure
        client.close
      end
    end

    # Close the server
    def close : Nil
      @socket.close
    end

    # Check if server is closed
    def closed? : Bool
      @socket.closed?
    end

    # Get local address
    def local_address : Address?
      @socket.local_address
    end
  end
end
