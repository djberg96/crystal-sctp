require "../src/sctp"

# Multi-homing SCTP Example
#
# This example demonstrates SCTP's multi-homing feature, which allows
# binding and connecting to multiple IP addresses for redundancy and
# automatic failover.

puts "SCTP Multi-homing Example\n"

# Start a server with multi-homing
spawn do
  server = SCTP::Socket.new

  # Bind to multiple addresses for redundancy
  # In a real scenario, these would be different network interfaces
  puts "Server: Binding to localhost (simulating multi-homing)"
  server.bind(["127.0.0.1"], 4001)
  server.listen

  puts "Server: Listening on port 4001"

  client = server.accept
  puts "Server: Client connected"

  # Receive messages
  3.times do
    message = client.read_string(1024)
    puts "Server received: #{message}"
    client.write("ACK: #{message}")
  end

  client.close
  server.close
  puts "Server: Connection closed"
end

# Give server time to start
sleep 0.5

# Client connects with multi-homing
puts "\nClient: Connecting to server with multi-homing"
client = SCTP::Socket.new

# Connect to multiple addresses (multi-homing)
# SCTP will automatically use alternative paths if one fails
client.connect(["127.0.0.1"], 4001)
puts "Client: Connected to server"

# Send messages
messages = [
  "Message 1: Primary path",
  "Message 2: With failover support",
  "Message 3: Redundant paths active",
]

messages.each do |msg|
  puts "Client sending: #{msg}"
  client.write(msg)

  response = client.read_string(1024)
  puts "Client received: #{response}"

  sleep 0.3
end

client.close
puts "\nClient: Connection closed"

sleep 0.5

puts "\n" + "="*50
puts "Multi-homing Benefits:"
puts "="*50
puts "✓ Multiple network paths for redundancy"
puts "✓ Automatic failover if one path fails"
puts "✓ Improved reliability for critical applications"
puts "✓ Transparent to the application layer"
puts "="*50

puts "\nExample completed!"
puts "\nNote: In production, bind to actual different network"
puts "interfaces (e.g., ['192.168.1.100', '10.0.0.100']) for"
puts "true redundancy."
