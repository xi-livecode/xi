require 'thread'
require 'logger'
require 'set'

Thread.abort_on_exception = true

module Xq
  class Clock
    DEFAULT_CPS  = 1.0
    INTERVAL_SEC = 25 / 1000.0

    def initialize(cps: DEFAULT_CPS)
      @mutex = Mutex.new
      @cps = cps
      @playing = true
      @streams = [].to_set
      @play_thread = Thread.new { thread_routine }
    end

    def subscribe(stream)
      @mutex.synchronize { @streams << stream }
    end

    def unsubscribe(stream)
      @mutex.synchronize { @streams.delete(stream) }
    end

    def cps
      @mutex.synchronize { @cps }
    end

    def cps=(new_cps)
      @mutex.synchronize { @cps = new_cps }
    end

    def playing?
      @mutex.synchronize { @playing }
    end

    def stopped?
      !playing?
    end

    def play
      @mutex.synchronize { @playing = true }
      self
    end
    alias_method :start, :play

    def stop
      @mutex.synchronize { @playing = false }
      self
    end
    alias_method :pause, :play

    def inspect
      "#<#{self.class.class_name}:#{"0x%014x" % object_id} cps=#{cps.inspect} #{playing? ? :playing : :stopped}>"
    end

    private

    def thread_routine
      loop do
        do_tick
        sleep INTERVAL_SEC
      end
    end

    def do_tick
      now = Time.now
      return unless playing?

      @streams.each do |stream|
        logger.info "sleep 1 sec"
        sleep 1
      end
    rescue => err
      logger.error(err)
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
