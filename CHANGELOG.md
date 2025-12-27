# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-27

### Added
- Initial release of Crystal SCTP library
- Complete bindings to libusrsctp
- High-level `SCTP::Socket` class inheriting from `IO`
- High-level `SCTP::Server` class similar to `TCPServer`
- Multi-streaming support with configurable stream counts
- Ordered and unordered message delivery
- Payload Protocol ID (PPID) support
- `SCTP::Address` class for endpoint management
- `SCTP::Stream` class for stream-specific operations
- `SCTP::StreamInfo` for stream metadata
- Comprehensive error handling with specific exception types
- Full test suite with specs for all functionality
- Example applications:
  - Hello World example
  - Echo server and client
  - Multi-stream demonstration
- Complete API documentation
- macOS and Linux support
- CI/CD pipeline with GitHub Actions
- Makefile for common development tasks

### Features
- Socket-like API familiar to Crystal developers
- Thread-safe context management
- Non-blocking I/O support
- SCTP_NODELAY option support
- Reading with stream information
- Graceful connection handling
- Proper resource cleanup with finalizers

[0.1.0]: https://github.com/yourusername/crystal-sctp/releases/tag/v0.1.0
