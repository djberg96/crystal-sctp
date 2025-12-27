# API Documentation

## SCTP Module

The main module containing all SCTP-related classes and functions.

### Constants

- `SCTP::VERSION` - Library version string

## SCTP::Socket

High-level SCTP socket class inheriting from `IO`.

### Initialization

```crystal
socket = SCTP::Socket.new(streams: 1, max_attempts: 4)
```

**Parameters:**
- `streams` (Int32): Number of outbound/inbound streams (default: 1)
- `max_attempts` (Int32): Maximum initialization attempts (default: 4)

### Properties

- `outbound_streams : Int32` - Number of outbound streams
- `inbound_streams : Int32` - Number of inbound streams
- `remote_address : Address?` - Remote endpoint address
- `local_address : Address?` - Local bound address

### Methods

#### bind(host : String, port : Int32)

Bind the socket to a local address.

```crystal
socket.bind("127.0.0.1", 3000)
```

**Raises:** `SCTP::BindError` if bind fails

---

#### listen(backlog : Int32 = 128)

Listen for incoming connections.

```crystal
socket.listen(128)
```

**Raises:** `SCTP::ListenError` if listen fails

---

#### accept : Socket

Accept an incoming connection.

```crystal
client = socket.accept
```

**Returns:** New `SCTP::Socket` for the client connection

**Raises:** `SCTP::AcceptError` if accept fails

---

#### connect(host : String, port : Int32)

Connect to a remote SCTP server.

```crystal
socket.connect("127.0.0.1", 3000)
```

**Raises:** `SCTP::ConnectError` if connection fails

---

#### write(slice : Bytes)

Write data to the socket (default stream 0).

```crystal
socket.write("Hello".to_slice)
```

**Raises:** `SCTP::SendError` if send fails

---

#### write(data : String | Bytes, stream : Int32 = 0, unordered : Bool = false, ppid : UInt32 = 0)

Write data to a specific stream with options.

```crystal
socket.write("Message", stream: 2, unordered: true, ppid: 1000_u32)
```

**Parameters:**
- `data` - Data to send (String or Bytes)
- `stream` - Stream ID (must be < outbound_streams)
- `unordered` - Whether to send unordered
- `ppid` - Payload Protocol ID

**Raises:**
- `SCTP::SendError` if send fails
- `ArgumentError` if stream is invalid

---

#### read(slice : Bytes) : Int32

Read data from the socket.

```crystal
buffer = Bytes.new(1024)
bytes_read = socket.read(buffer)
```

**Returns:** Number of bytes read

**Raises:** `SCTP::ReceiveError` if receive fails

---

#### read_string(max_size : Int32 = 4096) : String

Read and return a string.

```crystal
message = socket.read_string(1024)
```

**Returns:** String read from socket

---

#### read_with_info(slice : Bytes) : Tuple(Int32, UInt16, UInt32)

Read data with stream information.

```crystal
buffer = Bytes.new(1024)
bytes_read, stream_id, ppid = socket.read_with_info(buffer)
```

**Returns:** Tuple of (bytes_read, stream_id, ppid)

---

#### close

Close the socket.

```crystal
socket.close
```

---

#### closed? : Bool

Check if socket is closed.

```crystal
if socket.closed?
  puts "Socket is closed"
end
```

---

#### non_blocking=(value : Bool)

Set non-blocking mode.

```crystal
socket.non_blocking = true
```

---

#### non_blocking? : Bool

Check if socket is in non-blocking mode.

---

#### no_delay=(value : Bool)

Set SCTP_NODELAY option (disable Nagle's algorithm).

```crystal
socket.no_delay = true
```

## SCTP::Server

High-level server class similar to TCPServer.

### Initialization

```crystal
# Bind to specific interface
server = SCTP::Server.new("127.0.0.1", 3000, streams: 10, backlog: 128)

# Bind to all interfaces
server = SCTP::Server.new(3000)
```

### Methods

#### accept : Socket

Accept an incoming connection.

```crystal
client = server.accept
```

---

#### accept(&block : Socket -> _)

Accept with a block (automatically closes client).

```crystal
server.accept do |client|
  data = client.read_string(1024)
  client.write(data)
end
```

---

#### close

Close the server socket.

---

#### closed? : Bool

Check if server is closed.

---

#### local_address : Address?

Get the local address the server is bound to.

## SCTP::Address

Represents an SCTP endpoint address.

### Initialization

```crystal
addr = SCTP::Address.new("127.0.0.1", 3000)
```

### Class Methods

#### parse(address : String) : Address

Parse an address string.

```crystal
addr = SCTP::Address.parse("127.0.0.1:3000")
```

---

#### from_sockaddr(addr : LibUsrSCTP::SockaddrIn) : Address

Convert from C sockaddr structure.

### Instance Methods

#### to_sockaddr_in : LibUsrSCTP::SockaddrIn

Convert to C sockaddr_in structure.

---

#### to_s : String

Get string representation.

```crystal
puts addr.to_s  # => "127.0.0.1:3000"
```

### Properties

- `host : String` - IP address
- `port : Int32` - Port number

## SCTP::Stream

Represents an individual SCTP stream.

### Initialization

```crystal
stream = SCTP::Stream.new(socket, 2)
```

**Parameters:**
- `socket` - Parent SCTP socket
- `stream_id` - Stream ID (must be < socket.outbound_streams)

### Methods

#### write(data : String | Bytes, unordered : Bool = false, ppid : UInt32 = 0)

Write to this stream.

```crystal
stream.write("Message", unordered: true)
```

---

#### id : Int32

Get the stream ID.

## SCTP::StreamInfo

Information about a stream.

### Properties

- `stream_id : UInt16` - Stream identifier
- `ppid : UInt32` - Payload Protocol ID
- `unordered : Bool` - Whether delivery is unordered

## Exceptions

All SCTP exceptions inherit from `SCTP::Error`.

- `SCTP::Error` - Base exception class
- `SCTP::ConnectError` - Connection failed
- `SCTP::BindError` - Bind failed
- `SCTP::ListenError` - Listen failed
- `SCTP::AcceptError` - Accept failed
- `SCTP::SendError` - Send failed
- `SCTP::ReceiveError` - Receive failed

## LibUsrSCTP

Low-level C bindings to libusrsctp. See [lib_usrsctp.cr](../src/sctp/lib_usrsctp.cr) for details.

Most users should use the high-level `SCTP::Socket` and `SCTP::Server` classes instead of using LibUsrSCTP directly.
