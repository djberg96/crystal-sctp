# Crystal SCTP Examples

This directory contains example applications demonstrating various SCTP features.

## Examples

### hello_world.cr
The simplest SCTP example showing basic client-server communication.

```bash
crystal run examples/hello_world.cr
```

### server.cr & client.cr
A complete echo server and client demonstrating:
- Multi-stream support
- Client connection handling
- Reading with stream information
- Graceful shutdown

Run the server:
```bash
crystal run examples/server.cr
```

In another terminal, run the client:
```bash
crystal run examples/client.cr
```

### multi_stream.cr
Advanced example showing:
- Multiple independent streams (20 streams)
- Unordered delivery
- Payload Protocol IDs (PPID)
- Stream-specific message handling

```bash
crystal run examples/multi_stream.cr
```

## Features Demonstrated

- **Basic Communication**: Simple send/receive
- **Multi-streaming**: Independent data streams within one association
- **Server/Client Pattern**: Similar to TCP but with SCTP advantages
- **Stream Information**: Reading which stream messages arrive on
- **Unordered Delivery**: Messages that don't require ordering
- **PPID Support**: Custom payload protocol identifiers
- **Error Handling**: Proper exception handling and cleanup

## Tips

- Run the server before the client
- Press Ctrl+C to stop the server gracefully
- Experiment with different stream counts
- Try changing unordered delivery flags
- Monitor network traffic with Wireshark to see SCTP in action
