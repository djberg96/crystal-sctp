# Contributing to Crystal SCTP

Thank you for your interest in contributing to Crystal SCTP! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and inclusive. We welcome contributions from everyone.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Crystal version** (`crystal --version`)
- **OS and version** (macOS/Linux)
- **libusrsctp version**
- **Code sample** if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - why is this enhancement useful?
- **Proposed API** if applicable
- **Examples** of how it would be used

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes**
   - Follow the Crystal style guide
   - Add tests for new functionality
   - Update documentation as needed
3. **Ensure tests pass**
   ```bash
   crystal spec
   ```
4. **Check code formatting**
   ```bash
   crystal tool format --check
   ```
5. **Commit your changes**
   - Use clear, descriptive commit messages
   - Reference issues if applicable
6. **Push to your fork** and submit a pull request

## Development Setup

### Prerequisites

- Crystal >= 1.0.0
- libusrsctp

**macOS:**
```bash
brew install crystal usrsctp
```

**Linux (Ubuntu/Debian):**
```bash
# Install Crystal (see https://crystal-lang.org/install/)
sudo apt-get install libusrsctp-dev
```

### Building and Testing

```bash
# Install dependencies
shards install

# Build
crystal build src/sctp.cr

# Run tests
crystal spec

# Run specific test file
crystal spec spec/socket_spec.cr

# Format code
crystal tool format

# Check formatting
crystal tool format --check
```

### Project Structure

```
crystal-sctp/
├── src/
│   ├── sctp.cr              # Main module file
│   └── sctp/
│       ├── lib_usrsctp.cr   # C bindings
│       ├── socket.cr        # High-level socket
│       ├── server.cr        # High-level server
│       ├── address.cr       # Address handling
│       ├── stream.cr        # Stream classes
│       ├── context.cr       # Library initialization
│       └── errors.cr        # Exception types
├── spec/                    # Test files
├── examples/                # Example applications
└── API.md                   # API documentation
```

## Coding Standards

### Style Guide

- Follow the [Crystal style guide](https://crystal-lang.org/reference/conventions/coding_style.html)
- Use `crystal tool format` to format code
- Use meaningful variable and method names
- Add documentation comments for public APIs

### Documentation

- Document all public classes, methods, and modules
- Include code examples in documentation
- Update API.md when adding new public APIs
- Add examples for new features

### Testing

- Write specs for all new functionality
- Ensure specs pass on both macOS and Linux
- Test error conditions and edge cases
- Use descriptive test names

Example:
```crystal
describe SCTP::Socket do
  describe "#connect" do
    it "connects to remote server" do
      # Test implementation
    end

    it "raises ConnectError on failure" do
      # Test error handling
    end
  end
end
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when applicable

Example:
```
Add support for multi-homing

- Implement address list handling
- Add tests for multi-homed connections
- Update documentation

Fixes #123
```

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
