# Testing Guide

This guide explains how to run and write tests for Crystal SCTP.

## Running Tests

### Quick Start

```bash
# Run all tests
crystal spec

# Run with verbose output
crystal spec --verbose

# Run specific test file
crystal spec spec/socket_spec.cr

# Run specific test by line number
crystal spec spec/socket_spec.cr:45
```

### Using Make

```bash
# Run tests
make test

# Run with verbose output
make test-verbose
```

### Using Docker

```bash
# Build and run tests in Docker
docker-compose run crystal-sctp

# Or with docker directly
docker build -t crystal-sctp .
docker run crystal-sctp
```

## Test Structure

### Test Files

- `spec/spec_helper.cr` - Common setup and requires
- `spec/address_spec.cr` - Address parsing and conversion tests
- `spec/context_spec.cr` - Library initialization tests
- `spec/socket_spec.cr` - Socket operations tests
- `spec/server_spec.cr` - Server functionality tests
- `spec/stream_spec.cr` - Stream handling tests
- `spec/sctp_spec.cr` - Module-level tests

### Test Organization

Each test file follows this structure:

```crystal
require "./spec_helper"

describe SCTP::Socket do
  describe "#method_name" do
    it "does something" do
      # Test implementation
    end

    it "handles errors" do
      # Error handling tests
    end
  end
end
```

## Writing Tests

### Basic Test

```crystal
require "./spec_helper"

describe MyClass do
  it "creates an instance" do
    obj = MyClass.new
    obj.should be_a(MyClass)
  end
end
```

### Testing Socket Operations

```crystal
describe SCTP::Socket do
  it "connects and sends data" do
    # Create server
    server = SCTP::Socket.new
    server.bind("127.0.0.1", 0)
    server.listen

    # Get server address
    addr = server.local_address.not_nil!

    # Spawn server handler
    spawn do
      client = server.accept
      data = client.read_string(1024)
      client.write(data)
      client.close
    end

    # Small delay for server to start
    sleep 0.1

    # Create client
    client = SCTP::Socket.new
    client.connect(addr.host, addr.port)
    client.write("test")
    response = client.read_string(1024)

    # Assertions
    response.should eq("test")

    # Cleanup
    client.close
    server.close
  end
end
```

### Testing Error Conditions

```crystal
describe SCTP::Socket do
  it "raises on invalid operation" do
    socket = SCTP::Socket.new
    socket.close

    expect_raises(SCTP::Error, "Socket is closed") do
      socket.write("data")
    end
  end
end
```

### Testing Streams

```crystal
describe SCTP::Socket do
  it "sends on specific stream" do
    server = SCTP::Socket.new(streams: 5)
    server.bind("127.0.0.1", 0)
    server.listen

    received_stream = 0_u16

    spawn do
      client = server.accept
      buffer = Bytes.new(1024)
      _, stream_id, _ = client.read_with_info(buffer)
      received_stream = stream_id
      client.close
    end

    sleep 0.1

    if addr = server.local_address
      client = SCTP::Socket.new(streams: 5)
      client.connect(addr.host, addr.port)
      client.write("data", stream: 3)
      sleep 0.1
      client.close
    end

    received_stream.should eq(3_u16)
    server.close
  end
end
```

## Test Best Practices

### 1. Use Descriptive Names

```crystal
# Good
it "connects to remote server successfully" do
  # ...
end

# Bad
it "works" do
  # ...
end
```

### 2. Clean Up Resources

```crystal
it "test something" do
  socket = SCTP::Socket.new
  begin
    # Test code
  ensure
    socket.close  # Always clean up
  end
end
```

### 3. Use Small Delays for Spawned Fibers

```crystal
spawn do
  # Server code
end

sleep 0.1  # Give server time to start
# Client code
```

### 4. Test One Thing Per Test

```crystal
# Good - One assertion
it "connects to server" do
  # Setup and test connection only
end

it "sends data" do
  # Setup and test data sending only
end

# Bad - Multiple unrelated assertions
it "does everything" do
  # Connection test
  # Sending test
  # Receiving test
  # Error test
end
```

### 5. Use Proper Assertions

```crystal
# Good
value.should eq(expected)
socket.closed?.should be_true
list.size.should eq(10)

# Avoid
(value == expected).should be_true  # Less clear error messages
```

## Debugging Tests

### Run Single Test

```bash
# Run specific test file
crystal spec spec/socket_spec.cr

# Run test at specific line
crystal spec spec/socket_spec.cr:45
```

### Add Debug Output

```crystal
it "debugs something" do
  puts "Debug: socket state = #{socket.inspect}"
  pp some_variable  # Pretty print

  # Your test code
end
```

### Use Focus

```crystal
# Run only this test (requires ameba for focus support)
fit "focused test" do
  # This test will run
end

it "skipped test" do
  # This test will be skipped
end
```

## Common Test Issues

### Tests Hang

**Cause:** Server not accepting or client not connecting

**Solution:**
```crystal
# Add timeouts
spawn do
  server.accept { |c| c.write("ok") }
end
sleep 0.1  # Ensure server is ready
```

### Port Already in Use

**Cause:** Previous test didn't clean up

**Solution:**
```crystal
# Use port 0 for automatic assignment
server.bind("127.0.0.1", 0)

# Get actual port
addr = server.local_address.not_nil!
# Connect using addr.port
```

### Tests Pass Locally But Fail in CI

**Causes:**
- Different timing
- Different platform behavior
- Missing dependencies

**Solutions:**
- Increase sleep delays
- Add platform-specific tests
- Check CI has libusrsctp installed

## Coverage

Currently no built-in coverage tool. Manual coverage tracking:

- ✅ Socket creation and closing
- ✅ Bind, listen, accept
- ✅ Connect
- ✅ Read and write
- ✅ Multi-streaming
- ✅ Error conditions
- ✅ Address parsing
- ✅ Server operations
- ✅ Stream handling
- ✅ Non-blocking mode
- ✅ Socket options

## Continuous Integration

Tests run automatically on:
- Push to main branch
- Pull requests
- Multiple platforms (Ubuntu, macOS)
- Multiple Crystal versions (latest, nightly)

See `.github/workflows/ci.yml` for configuration.

## Performance Testing

For performance testing, create separate benchmark files:

```crystal
# benchmark/socket_throughput.cr
require "../src/sctp"
require "benchmark"

Benchmark.ips do |x|
  x.report("socket write") do
    # Benchmark code
  end
end
```

Run with:
```bash
crystal run --release benchmark/socket_throughput.cr
```

## Need Help?

- Check existing tests for examples
- Read [CONTRIBUTING.md](CONTRIBUTING.md)
- Open an issue for test failures
