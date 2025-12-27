module SCTP
  # Exception raised for SCTP-related errors
  class Error < Exception
  end

  # Exception raised when connection fails
  class ConnectError < Error
  end

  # Exception raised when bind fails
  class BindError < Error
  end

  # Exception raised when listen fails
  class ListenError < Error
  end

  # Exception raised when accept fails
  class AcceptError < Error
  end

  # Exception raised when send fails
  class SendError < Error
  end

  # Exception raised when receive fails
  class ReceiveError < Error
  end
end
