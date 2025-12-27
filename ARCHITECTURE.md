# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Application Layer                           │
│  (User Code: Echo Server, Client, Multi-stream Apps, etc.)     │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │ Uses
                ↓
┌─────────────────────────────────────────────────────────────────┐
│                  High-Level Crystal API                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │SCTP::Server  │  │SCTP::Socket  │  │SCTP::Stream  │         │
│  │              │  │  (extends IO)│  │              │         │
│  │- accept()    │  │- connect()   │  │- write()     │         │
│  │- listen()    │  │- bind()      │  │- id          │         │
│  │- close()     │  │- read()      │  └──────────────┘         │
│  └──────────────┘  │- write()     │                            │
│                    │- close()     │                            │
│  ┌──────────────┐  └──────────────┘  ┌──────────────┐         │
│  │SCTP::Address │                    │SCTP::Context │         │
│  │              │                    │              │         │
│  │- parse()     │                    │- init()      │         │
│  │- to_s()      │                    │- finish()    │         │
│  └──────────────┘                    └──────────────┘         │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │ Calls
                ↓
┌─────────────────────────────────────────────────────────────────┐
│                   LibUsrSCTP (C Bindings)                       │
├─────────────────────────────────────────────────────────────────┤
│  - usrsctp_init()          - usrsctp_bind()                    │
│  - usrsctp_socket()        - usrsctp_listen()                  │
│  - usrsctp_connect()       - usrsctp_accept()                  │
│  - usrsctp_sendv()         - usrsctp_recvv()                   │
│  - usrsctp_setsockopt()    - usrsctp_close()                   │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │ Links to
                ↓
┌─────────────────────────────────────────────────────────────────┐
│              libusrsctp.so / libusrsctp.dylib                   │
│                (Userspace SCTP Implementation)                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interactions

### Client Connection Flow

```
User Code                 SCTP::Socket           LibUsrSCTP        libusrsctp
    │                          │                     │                 │
    │ socket = new(streams:10) │                     │                 │
    ├─────────────────────────>│                     │                 │
    │                          │ usrsctp_socket()    │                 │
    │                          ├────────────────────>│                 │
    │                          │                     │ create_socket() │
    │                          │                     ├────────────────>│
    │                          │                     │<────────────────┤
    │                          │<────────────────────┤                 │
    │                          │ usrsctp_setsockopt()│                 │
    │                          ├────────────────────>│ (set streams)   │
    │                          │                     ├────────────────>│
    │                          │<────────────────────┤                 │
    │<─────────────────────────┤                     │                 │
    │                          │                     │                 │
    │ socket.connect(host,port)│                     │                 │
    ├─────────────────────────>│                     │                 │
    │                          │ usrsctp_connect()   │                 │
    │                          ├────────────────────>│                 │
    │                          │                     │ establish_conn()│
    │                          │                     ├────────────────>│
    │                          │                     │<────────────────┤
    │                          │<────────────────────┤                 │
    │<─────────────────────────┤                     │                 │
    │                          │                     │                 │
    │ socket.write("data", stream:5)                 │                 │
    ├─────────────────────────>│                     │                 │
    │                          │ usrsctp_sendmsg()   │                 │
    │                          ├────────────────────>│                 │
    │                          │                     │ send_on_stream()│
    │                          │                     ├────────────────>│
    │                          │                     │<────────────────┤
    │                          │<────────────────────┤                 │
    │<─────────────────────────┤                     │                 │
```

### Server Accept Flow

```
User Code             SCTP::Server/Socket       LibUsrSCTP        libusrsctp
    │                          │                     │                 │
    │ server = new(port:3000)  │                     │                 │
    ├─────────────────────────>│                     │                 │
    │                          │ usrsctp_socket()    │                 │
    │                          ├────────────────────>│                 │
    │                          │                     ├────────────────>│
    │                          │ usrsctp_bind()      │                 │
    │                          ├────────────────────>│                 │
    │                          │ usrsctp_listen()    │                 │
    │                          ├────────────────────>│                 │
    │<─────────────────────────┤                     │                 │
    │                          │                     │                 │
    │ client = server.accept() │                     │                 │
    ├─────────────────────────>│                     │                 │
    │                          │ usrsctp_accept()    │                 │
    │                          ├────────────────────>│                 │
    │                          │                     │ (blocks until   │
    │                          │                     │  connection)    │
    │                          │                     │<────────────────┤
    │                          │<────────────────────┤                 │
    │<─────────────────────────┤ (new Socket)        │                 │
```

## Class Hierarchy

```
IO (Crystal Standard Library)
 │
 └── SCTP::Socket
      │
      └── (used by) SCTP::Server
      │
      └── (uses) SCTP::Address
      │
      └── (uses) SCTP::Stream

Exception (Crystal Standard Library)
 │
 └── SCTP::Error
      ├── SCTP::ConnectError
      ├── SCTP::BindError
      ├── SCTP::ListenError
      ├── SCTP::AcceptError
      ├── SCTP::SendError
      └── SCTP::ReceiveError

Struct (Crystal Standard Library)
 │
 └── SCTP::StreamInfo
```

## Data Flow: Multi-Stream Communication

```
Application                    SCTP Layer               Network
     │                              │                      │
     │ write("control", stream:0)   │                      │
     ├─────────────────────────────>│                      │
     │                              │ [Stream 0] ─────────>│
     │                              │                      │
     │ write("data1", stream:1)     │                      │
     ├─────────────────────────────>│                      │
     │                              │ [Stream 1] ─────────>│
     │                              │                      │
     │ write("data2", stream:2)     │                      │
     ├─────────────────────────────>│                      │
     │                              │ [Stream 2] ─────────>│
     │                              │                      │
     │                              │ [Stream 1] <─────────│
     │ read_with_info() -> stream:1 │                      │
     │<─────────────────────────────┤                      │
     │                              │                      │
     │                              │ [Stream 0] <─────────│
     │ read_with_info() -> stream:0 │                      │
     │<─────────────────────────────┤                      │
```

## Memory Management

```
┌─────────────────────────────────────────┐
│        Crystal Object Lifecycle         │
├─────────────────────────────────────────┤
│                                         │
│  1. new() - Allocate Crystal object    │
│     ├─> Initialize @socket : Void*     │
│     ├─> Call LibUsrSCTP.usrsctp_socket│
│     └─> Register finalizer             │
│                                         │
│  2. use - Normal operations            │
│     ├─> bind(), connect(), etc.        │
│     └─> read(), write()                │
│                                         │
│  3. close() - Explicit cleanup         │
│     ├─> Call LibUsrSCTP.usrsctp_close │
│     ├─> Set @closed = true             │
│     └─> (finalizer becomes no-op)      │
│                                         │
│  4. finalize - Automatic cleanup       │
│     └─> If not closed, call close()    │
│                                         │
└─────────────────────────────────────────┘
```

## Thread Safety

```
┌──────────────────────────────────────────┐
│         SCTP::Context (Module)           │
├──────────────────────────────────────────┤
│  @@initialized : Bool                   │
│  @@mutex : Mutex                        │
│                                         │
│  def self.init                          │
│    @@mutex.synchronize do               │
│      unless @@initialized               │
│        LibUsrSCTP.usrsctp_init(...)    │
│        @@initialized = true             │
│      end                                │
│    end                                  │
│  end                                    │
└──────────────────────────────────────────┘
         │
         │ (Thread-safe initialization)
         │
    ┌────┴─────┬──────────┬──────────┐
    │          │          │          │
 Thread 1   Thread 2   Thread 3   Thread 4
 Socket A   Socket B   Socket C   Socket D
```

## Error Handling Flow

```
Application Code
     │
     │ socket.connect("invalid", 3000)
     │
     ↓
SCTP::Socket#connect
     │
     │ result = LibUsrSCTP.usrsctp_connect(...)
     │
     ↓
  [result < 0]
     │
     │ raise ConnectError.new("Failed to connect...")
     │
     ↓
Application Code
     │
     │ rescue ex : SCTP::ConnectError
     │   # Handle connection error
     │ rescue ex : SCTP::Error
     │   # Handle any SCTP error
     │ ensure
     │   socket.close
     │
```

## Platform Abstraction

```
┌─────────────────────────────────────────┐
│         Application Code                │
│    (Platform-independent API)           │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│         SCTP::Socket, etc.              │
│    (Platform-independent layer)         │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│         LibUsrSCTP Bindings             │
│  {% if flag?(:darwin) %}                │
│    @[Link("usrsctp")]                   │
│  {% else %}                             │
│    @[Link("usrsctp")]                   │
│  {% end %}                              │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│      libusrsctp (System Library)        │
│         macOS / Linux                   │
└─────────────────────────────────────────┘
```

## Key Design Decisions

### 1. IO Inheritance
**Decision:** `SCTP::Socket` inherits from `IO`

**Rationale:**
- Provides familiar read/write interface
- Compatible with Crystal's IO ecosystem
- Allows use with standard library tools

### 2. Context Management
**Decision:** Module-level context with Mutex

**Rationale:**
- libusrsctp requires global initialization
- Thread-safe singleton pattern
- Automatic cleanup with `at_exit`

### 3. Stream API
**Decision:** Both integrated and separate stream classes

**Rationale:**
- `socket.write(data, stream: N)` for convenience
- `SCTP::Stream` for stream-focused operations
- Flexibility for different use cases

### 4. Error Handling
**Decision:** Exception-based with specific types

**Rationale:**
- Consistent with Crystal conventions
- Allows targeted error handling
- Clear error messages

### 5. Resource Management
**Decision:** Finalizers + explicit close

**Rationale:**
- Explicit `close()` for predictable cleanup
- Finalizer as safety net
- `ensure` blocks recommended

## Performance Considerations

### Buffer Management
```
┌─────────────────────────────────────────┐
│  Application buffers data               │
│  ├─> Bytes.new(size)                    │
│  └─> Passed to LibUsrSCTP               │
│                                         │
│  LibUsrSCTP copies to internal buffers  │
│  ├─> SCTP association queue             │
│  └─> Network buffers                    │
└─────────────────────────────────────────┘
```

### Zero-Copy Opportunities
- Direct buffer passing to C layer
- No intermediate copies in Crystal layer
- Room for optimization in future versions

## Testing Architecture

```
┌─────────────────────────────────────────┐
│             Spec Files                  │
│  ├─> Unit tests (isolated components)  │
│  ├─> Integration tests (full flow)     │
│  └─> Error condition tests             │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│         SCTP Library Code               │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│      libusrsctp (Real Library)          │
│  Note: Tests use real SCTP, not mocks  │
└─────────────────────────────────────────┘
```

## Future Architecture Extensions

### Planned: Multi-homing
```
SCTP::Socket
 │
 ├─> bind_multi(["192.168.1.1", "10.0.0.1"], port)
 │
 └─> SCTP::MultiHomeAddress
      ├─> primary_address
      └─> secondary_addresses[]
```

### Planned: IPv6 Support
```
SCTP::Address
 │
 ├─> IPv4Address (existing)
 └─> IPv6Address (planned)
      ├─> to_sockaddr_in6
      └─> supports multi-homing
```

---

This architecture is designed to be:
- **Simple**: Easy to understand and use
- **Safe**: Memory-safe with proper cleanup
- **Extensible**: Room for additional features
- **Performant**: Minimal overhead over C library
- **Maintainable**: Clear separation of concerns
