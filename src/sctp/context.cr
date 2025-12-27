module SCTP
  # Manages SCTP library initialization and cleanup
  module Context
    @@initialized = false
    @@mutex = Mutex.new

    # Initialize the SCTP library
    def self.init : Void
      @@mutex.synchronize do
        unless @@initialized
          # Initialize with UDP encapsulation port 9899
          LibUsrSCTP.usrsctp_init(9899_u16, nil, nil)
          @@initialized = true

          # Register cleanup on exit
          at_exit { finish }
        end
      end
    end

    # Cleanup the SCTP library
    def self.finish : Void
      @@mutex.synchronize do
        if @@initialized
          LibUsrSCTP.usrsctp_finish
          @@initialized = false
        end
      end
    end

    # Check if initialized
    def self.initialized? : Bool
      @@initialized
    end
  end
end
