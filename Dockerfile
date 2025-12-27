# Use Crystal base image
FROM crystallang/crystal:latest

# Install libusrsctp
RUN apt-get update && \
    apt-get install -y libusrsctp-dev && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy shard files
COPY shard.yml shard.lock* ./

# Install dependencies
RUN shards install

# Copy source code
COPY . .

# Run tests by default
CMD ["crystal", "spec"]
