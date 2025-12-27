require "../src/sctp"

# Simple SCTP "Hello World" Example
#
# This demonstrates the most basic SCTP communication

puts "Simple SCTP Hello World Example\n"

# Create server
server = SCTP::Server.new("127.0.0.1", 5000)
puts "Server created on #{server.local_address}"

# Handle one connection
spawn do
  client = server.accept
  puts "Server: Client connected"

  message = client.read_string(1024)
  puts "Server received: #{message}"

  client.write("Hello from server!")
  client.close
end

sleep 0.5

# Create client and connect
client = SCTP::Socket.new
client.connect("127.0.0.1", 5000)
puts "Client: Connected to server"

client.write("Hello from client!")
response = client.read_string(1024)
puts "Client received: #{response}"

client.close
server.close

puts "\nExample completed successfully!"
