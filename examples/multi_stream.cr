require "../src/sctp"

# Multi-stream SCTP Example
#
# This example demonstrates advanced SCTP features:
# - Multiple independent streams
# - Unordered delivery
# - Custom Payload Protocol IDs (PPID)
# - Reading with stream information

puts "Multi-Stream SCTP Example"

# Start a server in the background
spawn do
  server = SCTP::Socket.new(streams: 20)
  server.bind("127.0.0.1", 4000)
  server.listen

  puts "Server listening on port 4000"

  client = server.accept
  puts "Client connected"

  # Receive messages from different streams
  10.times do
    buffer = Bytes.new(1024)
    bytes_read, stream_id, ppid = client.read_with_info(buffer)

    if bytes_read > 0
      message = String.new(buffer[0, bytes_read])
      puts "Server received on stream #{stream_id} (PPID: #{ppid}): #{message}"
    end
  end

  client.close
  server.close
end

# Give server time to start
sleep 0.5

# Client sends on multiple streams
client = SCTP::Socket.new(streams: 20)
client.connect("127.0.0.1", 4000)
puts "Client connected"

# Send on different streams with different options
10.times do |i|
  stream = i
  message = "Message #{i} on stream #{stream}"
  unordered = (i % 2 == 0) # Every other message is unordered
  ppid = 1000_u32 + i.to_u32

  client.write(message, stream: stream, unordered: unordered, ppid: ppid)
  puts "Client sent on stream #{stream} (unordered: #{unordered}, PPID: #{ppid})"

  sleep 0.1
end

sleep 1 # Wait for all messages to be processed

client.close
puts "\nExample completed!"
