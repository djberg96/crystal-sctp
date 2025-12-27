require "../src/sctp"

# Simple SCTP Client
#
# This example demonstrates:
# - Connecting to an SCTP server
# - Sending data on multiple streams
# - Receiving responses
# - Clean disconnection

puts "SCTP Client Example"
puts "Connecting to 127.0.0.1:3000..."

begin
  # Create socket with 10 streams
  client = SCTP::Socket.new(streams: 10)
  client.connect("127.0.0.1", 3000)
  puts "Connected!"

  # Enable SCTP_NODELAY for low latency
  client.no_delay = true

  # Send messages on different streams
  messages = [
    {stream: 0, text: "Hello from stream 0"},
    {stream: 1, text: "Hello from stream 1"},
    {stream: 2, text: "Message on stream 2"},
    {stream: 5, text: "Stream 5 is active"},
    {stream: 0, text: "Another message on stream 0"},
  ]

  messages.each do |msg|
    puts "Sending on stream #{msg[:stream]}: #{msg[:text]}"
    client.write(msg[:text], stream: msg[:stream])

    # Read response
    response = client.read_string(4096)
    puts "Received: #{response}"

    sleep 0.5 # Small delay between messages
  end

  puts "\nAll messages sent and echoed back!"
rescue ex : SCTP::ConnectError
  puts "Failed to connect: #{ex.message}"
  puts "Make sure the server is running (crystal run examples/server.cr)"
rescue ex : SCTP::Error
  puts "SCTP error: #{ex.message}"
ensure
  client.try &.close
  puts "Disconnected"
end
