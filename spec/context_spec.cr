require "./spec_helper"

describe SCTP::Context do
  describe ".init" do
    it "initializes SCTP library" do
      SCTP::Context.init
      SCTP::Context.initialized?.should be_true
    end

    it "is idempotent" do
      SCTP::Context.init
      SCTP::Context.init # Should not error
      SCTP::Context.initialized?.should be_true
    end
  end

  describe ".initialized?" do
    it "returns initialization state" do
      SCTP::Context.init
      SCTP::Context.initialized?.should be_true
    end
  end
end
