# Crystal SCTP

Crystal bindings and high-level API for [libusrsctp](https://github.com/sctplab/usrsctp), providing SCTP (Stream Control Transmission Protocol) support for macOS and Linux.

## Features

- 🚀 High-level Socket-like API for SCTP
- 🔧 Complete bindings to libusrsctp
- 🌐 Multi-homing support
- 📦 Multi-streaming support
- 🔒 Type-safe Crystal interface
- 🧪 Comprehensive test suite
- 🍎 macOS and Linux support

## Installation

1. Install libusrsctp:

   **macOS:**
   ```bash
   brew install usrsctp
   ```

   **Linux (Ubuntu/Debian):**
   ```bash
   sudo apt-get install libusrsctp-dev
   ```

2. Add this to your application's `shard.yml`:

   ```yaml
   dependencies:
     sctp:
       github: yourusername/crystal-sctp
   ```

3. Run `shards install`

## Usage

### Basic Server

```crystal
require "sctp"

# Create and bind an SCTP socket
server = SCTP::Socket.new
server.bind("127.0.0.1", 3000)
server.listen

puts "SCTP server listening on port 3000"

# Accept connections
loop do
  client = server.accept
  spawn do
    message = client.read_string(1024)
    puts "Received: #{message}"
    client.write("Echo: #{message}")
    client.close
  end
end
```

### Basic Client

```crystal
require "sctp"

# Connect to SCTP server
client = SCTP::Socket.new
client.connect("127.0.0.1", 3000)

client.write("Hello, SCTP!")
response = client.read_string(1024)
puts "Server response: #{response}"

client.close
```

### Multi-streaming

```crystal
require "sctp"

socket = SCTP::Socket.new(streams: 10)
socket.connect("127.0.0.1", 3000)

# Send on different streams
socket.write("Stream 0 data", stream: 0)
socket.write("Stream 1 data", stream: 1)
socket.write("Stream 5 data", stream: 5)

socket.close
```

## API Overview

The library provides several classes:

- `SCTP::Socket` - High-level socket interface (similar to TCPSocket/UDPSocket)
- `SCTP::Server` - High-level server interface (similar to TCPServer)
- `SCTP::Address` - Represents SCTP addresses with multi-homing support
- `SCTP::Stream` - Represents individual SCTP streams
- `LibUsrSCTP` - Low-level C bindings

## Development

```bash
# Run tests
crystal spec

# Run examples
crystal run examples/server.cr
crystal run examples/client.cr
```

## Contributing

1. Fork it (<https://github.com/yourusername/crystal-sctp/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT License - see LICENSE file for details

## Resources

- [SCTP RFC 4960](https://tools.ietf.org/html/rfc4960)
- [libusrsctp](https://github.com/sctplab/usrsctp)
- [Crystal Socket API](https://crystal-lang.org/api/Socket.html)
