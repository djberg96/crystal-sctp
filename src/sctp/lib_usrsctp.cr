require "socket"

{% if flag?(:darwin) %}
  @[Link("usrsctp")]
{% else %}
  @[Link("usrsctp")]
{% end %}

# Low-level bindings to libusrsctp
lib LibUsrSCTP
  alias Socklen = UInt32
  alias SocklenPtr = Socklen*
  alias Ssize = LibC::SSizeT

  # Socket types
  SOCK_STREAM    = 1
  SOCK_DGRAM     = 2
  SOCK_SEQPACKET = 5

  # Address families
  AF_INET  =   2
  AF_INET6 =  30 # macOS
  AF_CONN  = 123 # SCTP-specific

  # Protocol
  IPPROTO_SCTP = 132

  # SCTP-specific socket options
  SOL_SCTP                   =        132
  SCTP_RTOINFO               = 0x00000001
  SCTP_ASSOCINFO             = 0x00000002
  SCTP_INITMSG               = 0x00000003
  SCTP_NODELAY               = 0x00000004
  SCTP_AUTOCLOSE             = 0x00000005
  SCTP_PRIMARY_ADDR          = 0x00000007
  SCTP_ADAPTATION_LAYER      = 0x00000008
  SCTP_DISABLE_FRAGMENTS     = 0x00000009
  SCTP_PEER_ADDR_PARAMS      = 0x0000000a
  SCTP_DEFAULT_SEND_PARAM    = 0x0000000b
  SCTP_EVENTS                = 0x0000000c
  SCTP_I_WANT_MAPPED_V4_ADDR = 0x0000000d
  SCTP_MAXSEG                = 0x0000000e
  SCTP_STATUS                = 0x00000100

  # Send flags
  SCTP_UNORDERED = 0x0400
  SCTP_ADDR_OVER = 0x0200
  SCTP_ABORT     = 0x0800
  SCTP_EOF       = 0x0100

  # SCTP bindx flags
  SCTP_BINDX_ADD_ADDR = 0x01
  SCTP_BINDX_REM_ADDR = 0x02

  # Notification types
  SCTP_DATA_IO_EVENT          = 0x0001
  SCTP_ASSOCIATION_EVENT      = 0x0002
  SCTP_ADDRESS_EVENT          = 0x0004
  SCTP_SEND_FAILURE_EVENT     = 0x0008
  SCTP_PEER_ERROR_EVENT       = 0x0010
  SCTP_SHUTDOWN_EVENT         = 0x0020
  SCTP_PARTIAL_DELIVERY_EVENT = 0x0040
  SCTP_ADAPTATION_INDICATION  = 0x0080
  SCTP_AUTHENTICATION_EVENT   = 0x0100
  SCTP_STREAM_RESET_EVENT     = 0x0200

  # MSG flags
  MSG_NOTIFICATION = 0x2000

  struct SockaddrIn
    sin_len : UInt8
    sin_family : UInt8
    sin_port : UInt16
    sin_addr : InAddr
    sin_zero : StaticArray(UInt8, 8)
  end

  struct InAddr
    s_addr : UInt32
  end

  struct SockaddrIn6
    sin6_len : UInt8
    sin6_family : UInt8
    sin6_port : UInt16
    sin6_flowinfo : UInt32
    sin6_addr : In6Addr
    sin6_scope_id : UInt32
  end

  struct In6Addr
    s6_addr : StaticArray(UInt8, 16)
  end

  struct SockaddrStorage
    ss_len : UInt8
    ss_family : UInt8
    ss_pad1 : StaticArray(UInt8, 6)
    ss_align : Int64
    ss_pad2 : StaticArray(UInt8, 112)
  end

  struct SockaddrConn
    sconn_len : UInt8
    sconn_family : UInt16
    sconn_port : UInt16
    sconn_addr : Void*
  end

  struct SctpInitmsg
    sinit_num_ostreams : UInt16
    sinit_max_instreams : UInt16
    sinit_max_attempts : UInt16
    sinit_max_init_timeo : UInt16
  end

  struct SctpSndrcvinfo
    sinfo_stream : UInt16
    sinfo_ssn : UInt16
    sinfo_flags : UInt16
    sinfo_ppid : UInt32
    sinfo_context : UInt32
    sinfo_timetolive : UInt32
    sinfo_tsn : UInt32
    sinfo_cumtsn : UInt32
    sinfo_assoc_id : UInt32
  end

  struct SctpSndinfo
    snd_sid : UInt16
    snd_flags : UInt16
    snd_ppid : UInt32
    snd_context : UInt32
    snd_assoc_id : UInt32
  end

  struct SctpRcvinfo
    rcv_sid : UInt16
    rcv_ssn : UInt16
    rcv_flags : UInt16
    rcv_ppid : UInt32
    rcv_tsn : UInt32
    rcv_cumtsn : UInt32
    rcv_context : UInt32
    rcv_assoc_id : UInt32
  end

  struct SctpEvent
    se_assoc_id : UInt32
    se_type : UInt16
    se_on : UInt8
  end

  struct SctpEventSubscribe
    sctp_data_io_event : UInt8
    sctp_association_event : UInt8
    sctp_address_event : UInt8
    sctp_send_failure_event : UInt8
    sctp_peer_error_event : UInt8
    sctp_shutdown_event : UInt8
    sctp_partial_delivery_event : UInt8
    sctp_adaptation_layer_event : UInt8
    sctp_authentication_event : UInt8
    sctp_sender_dry_event : UInt8
    sctp_stream_reset_event : UInt8
  end

  struct Msghdr
    msg_name : Void*
    msg_namelen : Socklen
    msg_iov : Void*
    msg_iovlen : LibC::Int
    msg_control : Void*
    msg_controllen : Socklen
    msg_flags : LibC::Int
  end

  # Core functions
  fun usrsctp_init(port : UInt16, recv_cb : Void*, debug_printf : Void*) : Void
  fun usrsctp_finish : LibC::Int
  fun usrsctp_socket(domain : LibC::Int, type : LibC::Int, protocol : LibC::Int,
                     recv_cb : Void*, send_cb : Void*, sb_threshold : UInt32,
                     ulp_info : Void*) : Void*
  fun usrsctp_close(so : Void*) : Void
  fun usrsctp_bind(so : Void*, name : Void*, namelen : Socklen) : LibC::Int
  fun usrsctp_bindx(so : Void*, addrs : Void*, addrcnt : LibC::Int, flags : LibC::Int) : LibC::Int
  fun usrsctp_listen(so : Void*, backlog : LibC::Int) : LibC::Int
  fun usrsctp_accept(so : Void*, addr : Void*, addrlen : Socklen*) : Void*
  fun usrsctp_connect(so : Void*, name : Void*, addrlen : Socklen) : LibC::Int
  fun usrsctp_connectx(so : Void*, addrs : Void*, addrcnt : LibC::Int, id : UInt32*) : LibC::Int
  fun usrsctp_sendv(so : Void*, data : Void*, len : LibC::SizeT, addrs : Void*,
                    addrcnt : LibC::Int, info : Void*, infolen : Socklen,
                    infotype : LibC::UInt, flags : LibC::Int) : Ssize
  fun usrsctp_recvv(so : Void*, dbuf : Void*, len : LibC::SizeT, from : Void*,
                    fromlen : Socklen*, info : Void*, infolen : Socklen*,
                    infotype : LibC::UInt*, msg_flags : LibC::Int*) : Ssize
  fun usrsctp_setsockopt(so : Void*, level : LibC::Int, option_name : LibC::Int,
                         option_value : Void*, option_len : Socklen) : LibC::Int
  fun usrsctp_getsockopt(so : Void*, level : LibC::Int, option_name : LibC::Int,
                         option_value : Void*, option_len : Socklen*) : LibC::Int
  fun usrsctp_sendmsg(so : Void*, data : Void*, len : LibC::SizeT, to : Void*,
                      tolen : Socklen, ppid : UInt32, flags : UInt32,
                      stream_no : UInt16, timetolive : UInt32, context : UInt32) : Ssize
  fun usrsctp_shutdown(so : Void*, how : LibC::Int) : LibC::Int
  fun usrsctp_finish : LibC::Int

  # Socket control
  fun usrsctp_set_non_blocking(so : Void*, non_blocking : LibC::Int) : LibC::Int
  fun usrsctp_get_non_blocking(so : Void*) : LibC::Int

  # Utility functions
  fun usrsctp_sysctl_get_sasizeof : LibC::SizeT
  fun usrsctp_conninput(userdata : Void*, data : Void*, len : LibC::SizeT, ecn_bits : UInt8) : Void

  # Debug
  fun usrsctp_sysctl_set_sctp_debug_on(value : UInt32) : Void
end
