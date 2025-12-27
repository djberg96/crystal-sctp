# Quick Start Guide

Get started with Crystal SCTP in 5 minutes!

## Installation

### 1. Install libusrsctp

**macOS:**
```bash
brew install usrsctp
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install libusrsctp-dev
```

### 2. Add to your project

Add to `shard.yml`:
```yaml
dependencies:
  sctp:
    github: yourusername/crystal-sctp
```

Run:
```bash
shards install
```

## Your First SCTP Application

### Hello World Server & Client

Create `server.cr`:
```crystal
require "sctp"

server = SCTP::Server.new("127.0.0.1", 3000)
puts "Server listening on port 3000"

loop do
  server.accept do |client|
    message = client.read_string(1024)
    puts "Received: #{message}"
    client.write("Echo: #{message}")
  end
end
```

Create `client.cr`:
```crystal
require "sctp"

client = SCTP::Socket.new
client.connect("127.0.0.1", 3000)

client.write("Hello, SCTP!")
response = client.read_string(1024)
puts response  # => "Echo: Hello, SCTP!"

client.close
```

Run:
```bash
# Terminal 1
crystal run server.cr

# Terminal 2
crystal run client.cr
```

## Key Concepts

### 1. Streams

SCTP supports multiple independent streams in one connection:

```crystal
# Create socket with 10 streams
socket = SCTP::Socket.new(streams: 10)
socket.connect("127.0.0.1", 3000)

# Send on different streams
socket.write("Control message", stream: 0)
socket.write("Data stream 1", stream: 1)
socket.write("Data stream 2", stream: 2)
```

### 2. Ordered vs Unordered

```crystal
# Ordered delivery (default) - messages arrive in order
socket.write("Message 1", stream: 0)
socket.write("Message 2", stream: 0)

# Unordered delivery - messages may arrive in any order (faster)
socket.write("Fast message", stream: 1, unordered: true)
```

### 3. Reading with Stream Info

```crystal
buffer = Bytes.new(1024)
bytes_read, stream_id, ppid = socket.read_with_info(buffer)

puts "Received #{bytes_read} bytes on stream #{stream_id}"
```

### 4. Error Handling

```crystal
begin
  socket = SCTP::Socket.new
  socket.connect("127.0.0.1", 3000)
  socket.write("Hello")
rescue ex : SCTP::ConnectError
  puts "Connection failed: #{ex.message}"
rescue ex : SCTP::Error
  puts "SCTP error: #{ex.message}"
ensure
  socket.try &.close
end
```

## Common Patterns

### Echo Server

```crystal
require "sctp"

server = SCTP::Server.new(3000, streams: 10)

loop do
  client = server.accept
  spawn do
    begin
      loop do
        data = client.read_string(4096)
        break if data.empty?
        client.write(data)
      end
    ensure
      client.close
    end
  end
end
```

### Request-Response Client

```crystal
require "sctp"

def send_request(message : String) : String
  client = SCTP::Socket.new
  begin
    client.connect("127.0.0.1", 3000)
    client.write(message)
    client.read_string(4096)
  ensure
    client.close
  end
end

response = send_request("Hello")
puts response
```

### Multi-Stream Server

```crystal
require "sctp"

server = SCTP::Server.new(3000, streams: 5)

server.accept do |client|
  loop do
    buffer = Bytes.new(1024)
    bytes_read, stream_id, ppid = client.read_with_info(buffer)
    break if bytes_read == 0

    message = String.new(buffer[0, bytes_read])

    case stream_id
    when 0
      puts "Control: #{message}"
    when 1
      puts "Data: #{message}"
    else
      puts "Stream #{stream_id}: #{message}"
    end
  end
end
```

## Next Steps

- **Read the [API Documentation](API.md)** for detailed reference
- **Explore [examples/](examples/)** for more complete applications
- **Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)** if you run into issues
- **See [CONTRIBUTING.md](CONTRIBUTING.md)** to contribute

## Tips

1. **Always close sockets** - Use `ensure` blocks or `accept` with blocks
2. **Start with 1 stream** - Add more streams as needed
3. **Use `no_delay = true`** for low-latency applications
4. **Handle exceptions** - Network operations can fail
5. **Test both macOS and Linux** if deploying to both

## Performance Tips

```crystal
# Disable Nagle for low latency
socket.no_delay = true

# Use unordered when order doesn't matter
socket.write(data, unordered: true)

# Use appropriate buffer sizes
buffer = Bytes.new(8192)  # Larger for high throughput

# Reuse connections
# Create socket once, send multiple messages
```

## Common Mistakes

❌ **Don't:**
```crystal
# Forgetting to close
socket = SCTP::Socket.new
socket.connect("127.0.0.1", 3000)
# No close!

# Using wrong stream count
socket = SCTP::Socket.new(streams: 3)
socket.write("data", stream: 5)  # Error! Stream 5 doesn't exist
```

✅ **Do:**
```crystal
# Always close
socket = SCTP::Socket.new
begin
  socket.connect("127.0.0.1", 3000)
  socket.write("data")
ensure
  socket.close
end

# Check stream count
socket = SCTP::Socket.new(streams: 10)
socket.write("data", stream: 5)  # OK!
```

## Need Help?

- Check the [examples/](examples/) directory
- Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Open an issue on GitHub

Happy SCTP coding! 🚀
