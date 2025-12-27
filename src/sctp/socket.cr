require "socket"
require "io"

module SCTP
  # High-level SCTP socket implementation
  #
  # This class provides a Socket-like interface for SCTP communication,
  # supporting features like multi-streaming, multi-homing, and ordered/unordered delivery.
  #
  # Example:
  # ```
  # socket = SCTP::Socket.new
  # socket.connect("127.0.0.1", 3000)
  # socket.write("Hello, SCTP!")
  # response = socket.read_string(1024)
  # socket.close
  # ```
  class Socket < IO
    @socket : Void*
    @closed : Bool = false
    @remote_address : Address?
    @local_address : Address?

    # Number of outbound streams
    getter outbound_streams : Int32

    # Number of inbound streams
    getter inbound_streams : Int32

    # Create a new SCTP socket
    #
    # - `streams`: Number of streams to negotiate (default: 1)
    # - `max_attempts`: Maximum number of initialization attempts
    def initialize(streams : Int32 = 1, max_attempts : Int32 = 4)
      Context.init

      @outbound_streams = streams
      @inbound_streams = streams

      # Create socket using AF_CONN for userspace SCTP
      @socket = LibUsrSCTP.usrsctp_socket(
        LibUsrSCTP::AF_CONN,
        LibUsrSCTP::SOCK_STREAM,
        LibUsrSCTP::IPPROTO_SCTP,
        nil, nil, 0, nil
      )

      raise Error.new("Failed to create SCTP socket") if @socket.null?

      # Configure streams
      set_init_params(streams, streams, max_attempts)

      # Enable events
      enable_events
    end

    # Create socket from existing handle (for accept)
    protected def initialize(@socket : Void*, @remote_address : Address?)
      @outbound_streams = 1
      @inbound_streams = 1
      enable_events
    end

    # Bind the socket to a local address
    def bind(host : String, port : Int32) : Void
      raise Error.new("Socket is closed") if @closed

      @local_address = Address.new(host, port)
      addr = @local_address.not_nil!.to_sockaddr_in

      result = LibUsrSCTP.usrsctp_bind(@socket, pointerof(addr).as(Void*),
        sizeof(LibUsrSCTP::SockaddrIn))

      if result < 0
        raise BindError.new("Failed to bind to #{host}:#{port}")
      end
    end

    # Listen for incoming connections
    def listen(backlog : Int32 = 128) : Void
      raise Error.new("Socket is closed") if @closed

      result = LibUsrSCTP.usrsctp_listen(@socket, backlog)

      if result < 0
        raise ListenError.new("Failed to listen")
      end
    end

    # Accept an incoming connection
    def accept : Socket
      raise Error.new("Socket is closed") if @closed

      addr = LibUsrSCTP::SockaddrIn.new
      addrlen = sizeof(LibUsrSCTP::SockaddrIn).to_u32

      client_socket = LibUsrSCTP.usrsctp_accept(@socket, pointerof(addr).as(Void*),
        pointerof(addrlen))

      if client_socket.null?
        raise AcceptError.new("Failed to accept connection")
      end

      remote_addr = Address.from_sockaddr(addr)
      Socket.new(client_socket, remote_addr)
    end

    # Connect to a remote SCTP server
    def connect(host : String, port : Int32) : Void
      raise Error.new("Socket is closed") if @closed

      @remote_address = Address.new(host, port)
      addr = @remote_address.not_nil!.to_sockaddr_in

      result = LibUsrSCTP.usrsctp_connect(@socket, pointerof(addr).as(Void*),
        sizeof(LibUsrSCTP::SockaddrIn))

      if result < 0
        raise ConnectError.new("Failed to connect to #{host}:#{port}")
      end
    end

    # Write data to the socket
    def write(slice : Bytes) : Nil
      raise Error.new("Socket is closed") if @closed

      bytes_sent = LibUsrSCTP.usrsctp_sendv(@socket, slice.to_unsafe.as(Void*),
        slice.size, nil, 0, nil, 0, 0, 0)

      if bytes_sent < 0
        raise SendError.new("Failed to send data")
      end
    end

    # Write data to a specific stream
    def write(data : String | Bytes, stream : Int32 = 0,
              unordered : Bool = false, ppid : UInt32 = 0_u32) : Nil
      raise Error.new("Socket is closed") if @closed
      raise ArgumentError.new("Stream must be >= 0") if stream < 0
      raise ArgumentError.new("Stream #{stream} >= outbound_streams #{@outbound_streams}") if stream >= @outbound_streams

      bytes = data.is_a?(String) ? data.to_slice : data

      flags = 0_u32
      flags |= LibUsrSCTP::SCTP_UNORDERED if unordered

      bytes_sent = LibUsrSCTP.usrsctp_sendmsg(
        @socket,
        bytes.to_unsafe.as(Void*),
        bytes.size,
        nil, 0,
        ppid,
        flags,
        stream.to_u16,
        0_u32, 0_u32
      )

      if bytes_sent < 0
        raise SendError.new("Failed to send data on stream #{stream}")
      end
    end

    # Read data from the socket
    def read(slice : Bytes) : Int32
      raise Error.new("Socket is closed") if @closed

      bytes_received = LibUsrSCTP.usrsctp_recvv(@socket, slice.to_unsafe.as(Void*),
        slice.size, nil, nil, nil, nil, nil, nil)

      if bytes_received < 0
        raise ReceiveError.new("Failed to receive data")
      end

      bytes_received.to_i32
    end

    # Read a string from the socket
    def read_string(max_size : Int32 = 4096) : String
      buffer = Bytes.new(max_size)
      bytes_read = read(buffer)
      String.new(buffer[0, bytes_read])
    end

    # Read data with stream information
    def read_with_info(slice : Bytes) : Tuple(Int32, UInt16, UInt32)
      raise Error.new("Socket is closed") if @closed

      rcvinfo = LibUsrSCTP::SctpRcvinfo.new
      infolen = sizeof(LibUsrSCTP::SctpRcvinfo).to_u32
      infotype = 0_u32
      msg_flags = 0

      bytes_received = LibUsrSCTP.usrsctp_recvv(
        @socket,
        slice.to_unsafe.as(Void*),
        slice.size,
        nil, nil,
        pointerof(rcvinfo).as(Void*),
        pointerof(infolen),
        pointerof(infotype),
        pointerof(msg_flags)
      )

      if bytes_received < 0
        raise ReceiveError.new("Failed to receive data")
      end

      {bytes_received.to_i32, rcvinfo.rcv_sid, rcvinfo.rcv_ppid}
    end

    # Close the socket
    def close : Nil
      return if @closed

      LibUsrSCTP.usrsctp_close(@socket)
      @closed = true
    end

    # Check if socket is closed
    def closed? : Bool
      @closed
    end

    # Get remote address
    def remote_address : Address?
      @remote_address
    end

    # Get local address
    def local_address : Address?
      @local_address
    end

    # Set socket to non-blocking mode
    def non_blocking=(value : Bool)
      LibUsrSCTP.usrsctp_set_non_blocking(@socket, value ? 1 : 0)
    end

    # Check if socket is non-blocking
    def non_blocking? : Bool
      LibUsrSCTP.usrsctp_get_non_blocking(@socket) != 0
    end

    # Set SCTP_NODELAY option (disable Nagle)
    def no_delay=(value : Bool)
      val = value ? 1 : 0
      result = LibUsrSCTP.usrsctp_setsockopt(@socket, LibUsrSCTP::IPPROTO_SCTP,
        LibUsrSCTP::SCTP_NODELAY,
        pointerof(val).as(Void*), sizeof(Int32))
      raise Error.new("Failed to set SCTP_NODELAY") if result < 0
    end

    # Private helper methods

    private def set_init_params(outbound : Int32, inbound : Int32, max_attempts : Int32)
      initmsg = LibUsrSCTP::SctpInitmsg.new
      initmsg.sinit_num_ostreams = outbound.to_u16
      initmsg.sinit_max_instreams = inbound.to_u16
      initmsg.sinit_max_attempts = max_attempts.to_u16
      initmsg.sinit_max_init_timeo = 0_u16

      result = LibUsrSCTP.usrsctp_setsockopt(@socket, LibUsrSCTP::IPPROTO_SCTP,
        LibUsrSCTP::SCTP_INITMSG,
        pointerof(initmsg).as(Void*),
        sizeof(LibUsrSCTP::SctpInitmsg))

      raise Error.new("Failed to set stream parameters") if result < 0
    end

    private def enable_events
      events = LibUsrSCTP::SctpEventSubscribe.new
      events.sctp_data_io_event = 1_u8
      events.sctp_association_event = 1_u8
      events.sctp_address_event = 1_u8
      events.sctp_send_failure_event = 1_u8
      events.sctp_peer_error_event = 1_u8
      events.sctp_shutdown_event = 1_u8
      events.sctp_partial_delivery_event = 1_u8
      events.sctp_adaptation_layer_event = 1_u8
      events.sctp_stream_reset_event = 1_u8

      result = LibUsrSCTP.usrsctp_setsockopt(@socket, LibUsrSCTP::IPPROTO_SCTP,
        LibUsrSCTP::SCTP_EVENTS,
        pointerof(events).as(Void*),
        sizeof(LibUsrSCTP::SctpEventSubscribe))

      # Don't raise error if events can't be enabled (not critical)
    end

    def finalize
      close unless @closed
    end
  end
end
