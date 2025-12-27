require "socket"

module SCTP
  # Represents an SCTP address with optional multi-homing support
  class Address
    getter host : String
    getter port : Int32

    # Create a new SCTP address
    def initialize(@host : String, @port : Int32)
    end

    # Parse an address string (e.g., "127.0.0.1:3000")
    def self.parse(address : String) : Address
      parts = address.split(':')
      raise ArgumentError.new("Invalid address format") if parts.size != 2

      host = parts[0]
      port = parts[1].to_i
      new(host, port)
    end

    # Convert to sockaddr structure for IPv4
    def to_sockaddr_in : LibUsrSCTP::SockaddrIn
      addr = LibUsrSCTP::SockaddrIn.new
      addr.sin_len = sizeof(LibUsrSCTP::SockaddrIn).to_u8
      addr.sin_family = LibUsrSCTP::AF_INET.to_u8
      addr.sin_port = htons(@port.to_u16)

      # Convert IP string to binary
      ip_parts = @host.split('.')
      if ip_parts.size == 4
        bytes = ip_parts.map(&.to_u8)
        addr.sin_addr.s_addr = (bytes[0].to_u32 << 24) |
                               (bytes[1].to_u32 << 16) |
                               (bytes[2].to_u32 << 8) |
                               bytes[3].to_u32
      else
        raise ArgumentError.new("Invalid IPv4 address: #{@host}")
      end

      addr
    end

    # Convert from sockaddr structure
    def self.from_sockaddr(addr : LibUsrSCTP::SockaddrIn) : Address
      # Extract IP address
      s_addr = addr.sin_addr.s_addr
      ip = "#{(s_addr >> 24) & 0xFF}.#{(s_addr >> 16) & 0xFF}.#{(s_addr >> 8) & 0xFF}.#{s_addr & 0xFF}"
      port = ntohs(addr.sin_port)

      new(ip, port.to_i32)
    end

    def to_s(io : IO)
      io << @host << ':' << @port
    end

    def to_s : String
      "#{@host}:#{@port}"
    end

    # Network byte order conversions
    private def htons(value : UInt16) : UInt16
      ((value & 0xFF) << 8) | ((value >> 8) & 0xFF)
    end

    private def self.ntohs(value : UInt16) : UInt16
      ((value & 0xFF) << 8) | ((value >> 8) & 0xFF)
    end
  end
end
