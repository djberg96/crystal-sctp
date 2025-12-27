# Troubleshooting Guide

Common issues and solutions for Crystal SCTP.

## Installation Issues

### libusrsctp not found

**Error:**
```
ld: library not found for -lusrsctp
```

**Solution:**

**macOS:**
```bash
brew install usrsctp

# If still not found, check library path
brew info usrsctp
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install libusrsctp-dev

# For other distributions, you may need to build from source:
git clone https://github.com/sctplab/usrsctp.git
cd usrsctp
./bootstrap
./configure
make
sudo make install
sudo ldconfig
```

### Wrong Crystal version

**Error:**
```
Error: Crystal version mismatch
```

**Solution:**
```bash
# Check your Crystal version
crystal --version

# Update Crystal (macOS)
brew upgrade crystal

# Update Crystal (Linux)
# Follow instructions at https://crystal-lang.org/install/
```

## Runtime Issues

### Socket creation fails

**Error:**
```
SCTP::Error: Failed to create SCTP socket
```

**Possible causes:**
1. libusrsctp not properly initialized
2. Too many open file descriptors

**Solution:**
```bash
# Check file descriptor limits (Linux/macOS)
ulimit -n

# Increase if needed
ulimit -n 4096
```

### Connection refused

**Error:**
```
SCTP::ConnectError: Failed to connect to 127.0.0.1:3000
```

**Possible causes:**
1. Server not running
2. Wrong port number
3. Firewall blocking connection

**Solution:**
```bash
# Check if server is listening (Linux)
netstat -an | grep 3000

# Check if server is listening (macOS)
lsof -i :3000

# Make sure server is started before client
crystal run examples/server.cr  # Terminal 1
crystal run examples/client.cr  # Terminal 2
```

### Bind address in use

**Error:**
```
SCTP::BindError: Failed to bind to 127.0.0.1:3000
```

**Possible causes:**
1. Port already in use
2. Previous process didn't release socket

**Solution:**
```bash
# Find process using the port (Linux)
sudo netstat -tulpn | grep 3000

# Find process using the port (macOS)
lsof -i :3000

# Kill the process if needed
kill -9 <PID>

# Wait for TIME_WAIT to expire (usually 60 seconds)
# Or use a different port
```

### Stream ID out of range

**Error:**
```
ArgumentError: Stream 5 >= outbound_streams 3
```

**Cause:**
Trying to send on a stream that wasn't negotiated.

**Solution:**
```crystal
# Create socket with enough streams
socket = SCTP::Socket.new(streams: 10)

# Now you can use streams 0-9
socket.write("data", stream: 5)  # OK
```

## Performance Issues

### High latency

**Problem:** Messages take too long to arrive.

**Solution:**
```crystal
# Disable Nagle's algorithm
socket.no_delay = true

# Use unordered delivery when order doesn't matter
socket.write("data", unordered: true)
```

### Memory leaks

**Problem:** Memory usage keeps growing.

**Possible causes:**
1. Sockets not being closed
2. Accumulating connections

**Solution:**
```crystal
# Always close sockets
begin
  socket = SCTP::Socket.new
  socket.connect("127.0.0.1", 3000)
  # ... use socket ...
ensure
  socket.close  # Ensures cleanup even if exception occurs
end

# Or use blocks with Server
server.accept do |client|
  # ... handle client ...
end  # Automatically closes client
```

## Testing Issues

### Tests hang or timeout

**Possible causes:**
1. Server not properly accepting connections
2. Client not reading data, causing buffer to fill
3. Missing sleep between spawn and connection

**Solution:**
```crystal
# Give spawned fibers time to start
spawn do
  server.accept { |c| c.write("ok") }
end
sleep 0.1  # Small delay
client.connect(...)
```

### Tests fail on macOS but pass on Linux (or vice versa)

**Possible causes:**
1. Different socket buffer sizes
2. Different timing behavior
3. Platform-specific constants

**Solution:**
- Add platform-specific specs using `{% if flag?(:darwin) %}`
- Increase timeouts
- Use proper synchronization

## Platform-Specific Issues

### macOS: Undefined symbols

**Error:**
```
Undefined symbols for architecture x86_64:
  "_usrsctp_init", referenced from...
```

**Solution:**
```bash
# Make sure usrsctp is installed
brew install usrsctp

# Check architecture
crystal --version  # Should show your arch

# Reinstall if needed
brew reinstall usrsctp
```

### Linux: Symbol not found

**Error:**
```
cannot open shared object file: libusrsctp.so
```

**Solution:**
```bash
# Install development package
sudo apt-get install libusrsctp-dev

# Update library cache
sudo ldconfig

# Check library is found
ldconfig -p | grep usrsctp
```

## Debugging Tips

### Enable SCTP debug output

```crystal
# Add at start of your program
LibUsrSCTP.usrsctp_sysctl_set_sctp_debug_on(0xffffffff_u32)
```

### Capture network traffic

```bash
# Use Wireshark with SCTP filter
# Or tcpdump (root required)
sudo tcpdump -i lo0 'sctp' -w sctp.pcap

# Analyze with Wireshark
wireshark sctp.pcap
```

### Check socket state

```crystal
puts "Socket closed? #{socket.closed?}"
puts "Non-blocking? #{socket.non_blocking?}"
puts "Local address: #{socket.local_address}"
puts "Remote address: #{socket.remote_address}"
puts "Outbound streams: #{socket.outbound_streams}"
puts "Inbound streams: #{socket.inbound_streams}"
```

## Getting Help

If you're still experiencing issues:

1. **Check the examples** - They demonstrate working code
2. **Search existing issues** - Someone may have had the same problem
3. **Create an issue** - Include:
   - Crystal version (`crystal --version`)
   - OS and version
   - libusrsctp version
   - Minimal code to reproduce
   - Full error message and stack trace

## Known Limitations

- IPv6 support is not yet implemented
- Multi-homing requires additional implementation
- Some advanced SCTP features not yet exposed
- Performance not optimized for high-throughput scenarios

See [GitHub Issues](https://github.com/yourusername/crystal-sctp/issues) for ongoing work.
