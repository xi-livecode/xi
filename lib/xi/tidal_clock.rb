require "websocket"
require "time"

module Xi
  class TidalClock < Clock
    SYNC_INTERVAL_SEC = 100 / 1000.0

    attr_reader :server, :port, :attached
    alias_method :attached?, :attached

    def initialize(server: 'localhost', port: 9160, **opts)
      @server = server
      @port = port
      @attached = true

      super(opts)

      @ws_thread = Thread.new { ws_thread_routine }
    end

    def cps=(new_cps)
      fail NotImplementedError, 'cps is read-only'
    end

    def dettach
      @attached = false
      self
    end

    def attach
      @attached = true
      self
    end

    private

    def ws_thread_routine
      loop do
        do_ws_sync
        sleep INTERVAL_SEC
      end
    end

    def do_ws_sync
      return unless @attached

      # Try to connect to websocket server
      connect
      return if @socket.nil? || @socket.closed?

      # Offer a handshake
      @handshake = WebSocket::Handshake::Client.new(url: "ws://#{@server}:#{@port}")
      @socket.puts @handshake.to_s

      # Read server response
      while line = @socket.gets
        @handshake << line
        break if @handshake.finished?
      end

      unless @handshake.finished?
        debug(__method__, "Handshake didn't finished. Disconnect")
        @socket.close
        return
      end

      unless @handshake.valid?
        debug(__method__, "Handshake is not valid. Disconnect")
        @socket.close
        return
      end

      frame = WebSocket::Frame::Incoming::Server.new(version: @handshake.version)

      # Read loop
      loop do
        data, _ = @socket.recvfrom(4096)
        break if data.empty?

        frame << data
        while f = frame.next
          if (f.type == :close)
            debug(__method__, "Close frame received. Disconnect")
            @socket.close
            return
          else
            debug(__method__, "Frame: #{f}")
            hash = parse_frame_body(f.to_s)
            update_clock_from_server_data(hash)
          end
        end
      end

    rescue => err
      error(err)
    end

    def connect
      @socket = TCPSocket.new(@server, @port)
    rescue => err
      error(err)
      sleep 1
    end

    def parse_frame_body(body)
      h = {}
      ts, _, cps = body.split(',')
      h[:ts] = Time.parse(ts)
      h[:cps] = cps.to_f
      h
    end

    def update_clock_from_server_data(h)
      @init_ts = h[:ts].to_f
      @cps = h[:cps]
    end
  end
end
