require "./spec_helper"

describe SCTP::Address do
  describe "#initialize" do
    it "creates an address with host and port" do
      addr = SCTP::Address.new("127.0.0.1", 3000)
      addr.host.should eq("127.0.0.1")
      addr.port.should eq(3000)
    end
  end

  describe ".parse" do
    it "parses address string" do
      addr = SCTP::Address.parse("127.0.0.1:3000")
      addr.host.should eq("127.0.0.1")
      addr.port.should eq(3000)
    end

    it "raises on invalid format" do
      expect_raises(ArgumentError, "Invalid address format") do
        SCTP::Address.parse("invalid")
      end
    end
  end

  describe "#to_sockaddr_in" do
    it "converts to sockaddr_in structure" do
      addr = SCTP::Address.new("127.0.0.1", 3000)
      sockaddr = addr.to_sockaddr_in

      sockaddr.sin_family.should eq(LibUsrSCTP::AF_INET.to_u8)
      # Port should be in network byte order
      sockaddr.sin_port.should_not eq(0_u16)
    end

    it "handles different IP addresses" do
      addr = SCTP::Address.new("192.168.1.100", 8080)
      sockaddr = addr.to_sockaddr_in

      # Check that address was converted
      sockaddr.sin_addr.s_addr.should_not eq(0_u32)
    end

    it "raises on invalid IPv4" do
      expect_raises(ArgumentError, /Invalid IPv4 address/) do
        addr = SCTP::Address.new("invalid", 3000)
        addr.to_sockaddr_in
      end
    end
  end

  describe ".from_sockaddr" do
    it "converts from sockaddr_in structure" do
      original = SCTP::Address.new("127.0.0.1", 3000)
      sockaddr = original.to_sockaddr_in

      converted = SCTP::Address.from_sockaddr(sockaddr)
      converted.host.should eq("127.0.0.1")
      converted.port.should eq(3000)
    end
  end

  describe "#to_s" do
    it "returns string representation" do
      addr = SCTP::Address.new("127.0.0.1", 3000)
      addr.to_s.should eq("127.0.0.1:3000")
    end
  end
end
