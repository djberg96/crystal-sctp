require "socket"

module SCTP
  # Helper for byte order conversions on macOS/BSD systems
  lib LibC
    fun htonl(hostlong : UInt32) : UInt32
    fun ntohl(netlong : UInt32) : UInt32
    fun htons(hostshort : UInt16) : UInt16
    fun ntohs(netshort : UInt16) : UInt16
  end

  # Manages UDP transport for SCTP encapsulation
  class UDPTransport
    @@instance : UDPTransport?
    @@mutex = Mutex.new

    @udp_socket : UDPSocket
    @running = true
    @receive_fiber : Fiber?

    def self.instance
      @@mutex.synchronize do
        # Check if existing instance has a closed socket
        if inst = @@instance
          if inst.@udp_socket.closed?
            @@instance = nil
          end
        end
        @@instance ||= new
      end
    end

    def initialize
      @udp_socket = UDPSocket.new
      begin
        @udp_socket.bind("127.0.0.1", 9899)
      rescue ex : ::Socket::BindError
        # Port already in use, try to reuse the existing socket
        # This shouldn't happen with singleton pattern but just in case
        @udp_socket.close rescue nil
        raise ex
      end
      start_receiver
    end

    # Send callback for usrsctp
    def self.send_callback(addr : Void*, buffer : Void*, length : ::LibC::SizeT, tos : UInt8, set_df : UInt8) : ::LibC::Int
      transport = @@instance
      return -1 unless transport

      begin
        # Extract destination from addr (should be sockaddr_in)
        sockaddr = addr.as(LibUsrSCTP::SockaddrIn*)
        if sockaddr.null?
          # If no address provided, we can't send
          return -1
        end

        # Convert network byte order port and address
        port = SCTP::LibC.ntohs(sockaddr.value.sin_port).to_i32
        ip_addr = SCTP::LibC.ntohl(sockaddr.value.sin_addr.s_addr)
        ip_str = "#{(ip_addr >> 24) & 0xFF}.#{(ip_addr >> 16) & 0xFF}.#{(ip_addr >> 8) & 0xFF}.#{ip_addr & 0xFF}"

        # Copy buffer data
        data = Bytes.new(buffer.as(UInt8*), length)

        # Send via UDP socket
        dest_addr = ::Socket::IPAddress.new(ip_str, port)
        transport.@udp_socket.send(data, dest_addr)
        STDERR.puts "DEBUG: Sent #{length} bytes to #{ip_str}:#{port}" if ENV["SCTP_DEBUG"]?
        return length.to_i32
      rescue ex
        STDERR.puts "UDP send error: #{ex.message}"
        return -1
      end
    end

    private def start_receiver
      @receive_fiber = spawn do
        buffer = Bytes.new(65536)
        while @running
          begin
            bytes_read, addr = @udp_socket.receive(buffer)
            next if bytes_read == 0

            # Build sockaddr_in for the source
            sockaddr = LibUsrSCTP::SockaddrIn.new
            sockaddr.sin_family = LibUsrSCTP::AF_INET.to_u8

            # Parse address and port from Socket::Address
            case addr
            when ::Socket::IPAddress
              sockaddr.sin_port = SCTP::LibC.htons(addr.port.to_u16)

              # Parse IP address
              ip_parts = addr.address.split('.')
              if ip_parts.size == 4
                ip_bytes = ip_parts.map(&.to_u32)
                sockaddr.sin_addr.s_addr = SCTP::LibC.htonl(
                  (ip_bytes[0] << 24) | (ip_bytes[1] << 16) | (ip_bytes[2] << 8) | ip_bytes[3]
                )
              end
            end

            # Deliver to usrsctp stack
            LibUsrSCTP.usrsctp_conninput(pointerof(sockaddr).as(Void*), buffer.to_unsafe.as(Void*), bytes_read, 0_u8)
          rescue ex
            break unless @running
            STDERR.puts "UDP receive error: #{ex.message}"
          end
        end
      end
    end

    def stop
      @running = false
      @udp_socket.close rescue nil
    end
  end

  # Manages SCTP library initialization and cleanup
  module Context
    @@initialized = false
    @@mutex = Mutex.new
    @@transport : UDPTransport?

    # Initialize the SCTP library with UDP encapsulation
    def self.init : Void
      @@mutex.synchronize do
        unless @@initialized
          # Start UDP transport first
          @@transport = UDPTransport.instance

          # Create callback pointer
          send_cb = ->UDPTransport.send_callback(Void*, Void*, ::LibC::SizeT, UInt8, UInt8)

          # Initialize with UDP encapsulation port 9899
          LibUsrSCTP.usrsctp_init(9899_u16, send_cb, nil)
          @@initialized = true

          # Register cleanup on exit
          at_exit { finish }
        end
      end
    end

    # Cleanup the SCTP library
    def self.finish : Void
      @@mutex.synchronize do
        if @@initialized
          LibUsrSCTP.usrsctp_finish
          @@transport.try(&.stop)
          @@transport = nil
          @@initialized = false
        end
      end
    end

    # Check if initialized
    def self.initialized? : Bool
      @@initialized
    end
  end
end
