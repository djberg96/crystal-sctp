require "./spec_helper"

describe SCTP do
  it "has version" do
    SCTP::VERSION.should be_a(String)
    SCTP::VERSION.should eq("0.1.0")
  end
end
