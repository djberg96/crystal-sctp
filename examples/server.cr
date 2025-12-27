require "../src/sctp"

# Simple SCTP Echo Server
#
# This example demonstrates:
# - Creating an SCTP server
# - Accepting multiple client connections
# - Reading and echoing data back
# - Multi-streaming support

puts "Starting SCTP Echo Server on port 3000..."

server = SCTP::Server.new("127.0.0.1", 3000, streams: 10)
puts "Server listening on #{server.local_address}"
puts "Press Ctrl+C to stop"

# Handle graceful shutdown
Signal::INT.trap do
  puts "\nShutting down server..."
  server.close
  exit(0)
end

loop do
  begin
    # Accept incoming connection
    client = server.accept
    puts "Client connected from #{client.remote_address}"

    # Handle client in a separate fiber
    spawn do
      begin
        loop do
          # Read with stream information
          buffer = Bytes.new(4096)
          bytes_read, stream_id, ppid = client.read_with_info(buffer)

          break if bytes_read == 0

          message = String.new(buffer[0, bytes_read])
          puts "Received on stream #{stream_id}: #{message}"

          # Echo back on the same stream
          client.write(message, stream: stream_id.to_i32)
        end
      rescue ex : SCTP::Error
        puts "Client error: #{ex.message}"
      ensure
        puts "Client disconnected"
        client.close
      end
    end
  rescue ex : SCTP::Error
    puts "Server error: #{ex.message}"
  end
end
