# Crystal SCTP - Documentation Index

Welcome to the Crystal SCTP library documentation! This index will help you find the information you need.

## 📚 Quick Links

| Document | Description | For |
|----------|-------------|-----|
| [README.md](README.md) | Project overview and quick examples | Everyone |
| [QUICKSTART.md](QUICKSTART.md) | Get started in 5 minutes | Beginners |
| [API.md](API.md) | Complete API reference | Developers |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design and internals | Contributors |
| [TESTING.md](TESTING.md) | Testing guide | Developers |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions | Users having problems |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute | Contributors |
| [CHANGELOG.md](CHANGELOG.md) | Version history | Everyone |

## 🎯 Getting Started Path

1. **Complete Beginner to SCTP?**
   - Start with [README.md](README.md) - Overview
   - Then [QUICKSTART.md](QUICKSTART.md) - First application
   - Run [examples/hello_world.cr](examples/hello_world.cr)

2. **Familiar with Crystal, new to this library?**
   - Read [README.md](README.md) - Features and installation
   - Check [API.md](API.md) - API reference
   - Explore [examples/](examples/) directory

3. **Experienced developer looking for specific features?**
   - Jump to [API.md](API.md) - Find specific methods
   - Check [ARCHITECTURE.md](ARCHITECTURE.md) - Understand internals

4. **Want to contribute?**
   - Read [CONTRIBUTING.md](CONTRIBUTING.md) - Guidelines
   - Check [ARCHITECTURE.md](ARCHITECTURE.md) - Design decisions
   - See [TESTING.md](TESTING.md) - Writing tests

## 📖 Documentation by Topic

### Installation

- [README.md - Installation](README.md#installation) - Dependencies and setup
- [QUICKSTART.md - Installation](QUICKSTART.md#installation) - Step-by-step
- [TROUBLESHOOTING.md - Installation Issues](TROUBLESHOOTING.md#installation-issues) - Common problems

### Basic Usage

- [QUICKSTART.md - Your First Application](QUICKSTART.md#your-first-sctp-application)
- [examples/hello_world.cr](examples/hello_world.cr) - Simplest example
- [API.md - SCTP::Socket](API.md#sctpsocket) - Socket operations

### Server Development

- [README.md - Basic Server](README.md#basic-server)
- [examples/server.cr](examples/server.cr) - Echo server
- [API.md - SCTP::Server](API.md#sctpserver) - Server API

### Client Development

- [README.md - Basic Client](README.md#basic-client)
- [examples/client.cr](examples/client.cr) - Client example
- [API.md - SCTP::Socket#connect](API.md#connecthost--string-port--int32)

### Multi-streaming

- [README.md - Multi-streaming](README.md#multi-streaming)
- [QUICKSTART.md - Streams](QUICKSTART.md#1-streams)
- [examples/multi_stream.cr](examples/multi_stream.cr) - Advanced example
- [API.md - SCTP::Stream](API.md#sctpstream) - Stream API

### Error Handling

- [QUICKSTART.md - Error Handling](QUICKSTART.md#4-error-handling)
- [API.md - Exceptions](API.md#exceptions) - Exception types
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common errors

### Testing

- [TESTING.md](TESTING.md) - Complete testing guide
- [spec/](spec/) - Test examples

### Advanced Topics

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [API.md - LibUsrSCTP](API.md#libusrsctp) - Low-level bindings
- [TROUBLESHOOTING.md - Performance Issues](TROUBLESHOOTING.md#performance-issues)

## 📂 Code Examples by Use Case

### Echo Server
```crystal
# See: examples/server.cr
server = SCTP::Server.new(3000)
server.accept { |c| c.write(c.read_string(1024)) }
```
**Documentation:** [API.md - SCTP::Server](API.md#sctpserver)

### Simple Client
```crystal
# See: examples/client.cr
client = SCTP::Socket.new
client.connect("127.0.0.1", 3000)
client.write("Hello")
```
**Documentation:** [API.md - SCTP::Socket#connect](API.md#connecthost--string-port--int32)

### Multi-stream Communication
```crystal
# See: examples/multi_stream.cr
socket = SCTP::Socket.new(streams: 10)
socket.write("Control", stream: 0)
socket.write("Data", stream: 1)
```
**Documentation:** [API.md - SCTP::Socket#write (with streams)](API.md#writedata--string--bytes-stream--int32--0-unordered--bool--false-ppid--uint32--0)

### Read with Stream Info
```crystal
buffer = Bytes.new(1024)
bytes, stream_id, ppid = socket.read_with_info(buffer)
```
**Documentation:** [API.md - read_with_info](API.md#read_with_infoslice--bytes--tupleint32-uint16-uint32)

## 🔧 Development Resources

### Project Structure
```
crystal-sctp/
├── src/sctp/          # Source code
├── spec/              # Tests
├── examples/          # Example applications
└── [docs]             # You are here
```

### Build & Test Commands
```bash
make build      # Build the project
make test       # Run tests
make examples   # Run examples
```
**Full reference:** [Makefile](Makefile)

### CI/CD
- [.github/workflows/ci.yml](.github/workflows/ci.yml) - GitHub Actions

### Docker
- [Dockerfile](Dockerfile) - Container setup
- [docker-compose.yml](docker-compose.yml) - Multi-container setup

## 🐛 Troubleshooting Quick Reference

| Problem | Solution Document | Section |
|---------|------------------|---------|
| Installation fails | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Installation Issues |
| Connection refused | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Connection refused |
| Socket creation fails | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Socket creation fails |
| Port already in use | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Bind address in use |
| High latency | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Performance Issues |
| Memory leaks | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Memory leaks |
| Tests hang | [TESTING.md](TESTING.md) | Tests hang or timeout |

## 📝 API Quick Reference

### Core Classes

| Class | Purpose | Documentation |
|-------|---------|---------------|
| `SCTP::Socket` | Main socket class | [API.md - Socket](API.md#sctpsocket) |
| `SCTP::Server` | Server class | [API.md - Server](API.md#sctpserver) |
| `SCTP::Address` | Address handling | [API.md - Address](API.md#sctpaddress) |
| `SCTP::Stream` | Stream operations | [API.md - Stream](API.md#sctpstream) |

### Key Methods

| Method | Class | Purpose |
|--------|-------|---------|
| `connect` | Socket | Connect to server |
| `bind` | Socket | Bind to address |
| `listen` | Socket | Listen for connections |
| `accept` | Socket/Server | Accept connection |
| `write` | Socket | Send data |
| `read` | Socket | Receive data |
| `close` | Socket/Server | Close connection |

## 🤝 Community & Support

### Getting Help
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/yourusername/crystal-sctp/issues)
3. Create a new issue with:
   - Crystal version
   - OS and version
   - Code to reproduce
   - Error message

### Contributing
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Fork the repository
3. Make changes with tests
4. Submit pull request

### Reporting Bugs
See [CONTRIBUTING.md - Reporting Bugs](CONTRIBUTING.md#reporting-bugs)

### Suggesting Features
See [CONTRIBUTING.md - Suggesting Enhancements](CONTRIBUTING.md#suggesting-enhancements)

## 📊 Project Status

- **Version:** 0.1.0
- **Status:** Initial Release
- **Crystal:** >= 1.0.0
- **Platforms:** macOS, Linux
- **License:** MIT

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## 🎓 Learning Resources

### SCTP Protocol
- [SCTP RFC 4960](https://tools.ietf.org/html/rfc4960)
- [Wikipedia - SCTP](https://en.wikipedia.org/wiki/Stream_Control_Transmission_Protocol)

### libusrsctp
- [usrsctp GitHub](https://github.com/sctplab/usrsctp)
- [usrsctp Manual](https://github.com/sctplab/usrsctp/blob/master/Manual.md)

### Crystal Language
- [Crystal Language](https://crystal-lang.org/)
- [Crystal Documentation](https://crystal-lang.org/docs/)
- [Crystal API Docs](https://crystal-lang.org/api/)

## 📋 Checklist for New Users

- [ ] Install libusrsctp
- [ ] Install Crystal
- [ ] Clone/download crystal-sctp
- [ ] Run `shards install`
- [ ] Run `crystal spec` to verify
- [ ] Try `examples/hello_world.cr`
- [ ] Read [QUICKSTART.md](QUICKSTART.md)
- [ ] Build your first application

## 📋 Checklist for Contributors

- [ ] Read [CONTRIBUTING.md](CONTRIBUTING.md)
- [ ] Read [ARCHITECTURE.md](ARCHITECTURE.md)
- [ ] Read [TESTING.md](TESTING.md)
- [ ] Set up development environment
- [ ] Run tests successfully
- [ ] Check code formatting
- [ ] Review existing issues
- [ ] Make your contribution

---

**Need something not listed here?** Open an issue and we'll add it to the documentation!

**Found a documentation error?** Please submit a pull request!

**Have a question?** Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or open an issue.
