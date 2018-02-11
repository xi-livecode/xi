require 'thread'
require 'set'

Thread.abort_on_exception = true

module Xi
  class Clock
    DEFAULT_CPS  = 1.0
    INTERVAL_SEC = 10 / 1000.0

    attr_reader :init_ts, :latency

    def initialize(cps: DEFAULT_CPS)
      @mutex = Mutex.new
      @cps = cps
      @playing = true
      @streams = [].to_set
      @init_ts = Time.now.to_i.to_f
      @latency = 0.0
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
      @mutex.synchronize { @cps = new_cps.to_f }
    end

    def bps
      @mutex.synchronize { @cps * 2 }
    end

    def bps=(new_bps)
      @mutex.synchronize { @cps = new_bps / 2.0 }
    end

    def bpm
      @mutex.synchronize { @cps * 120 }
    end

    def bpm=(new_bpm)
      @mutex.synchronize { @cps = new_bpm / 120.0 }
    end

    def latency=(new_latency)
      @latency = new_latency.to_f
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

    def seconds_per_cycle
      @mutex.synchronize { 1.0 / @cps }
    end

    def current_time
      Time.now.to_f - @init_ts + @latency
    end

    def current_cycle
      current_time * cps
    end

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} " \
        "cps=#{cps.inspect} #{playing? ? :playing : :stopped}>"
    end

    private

    def thread_routine
      loop do
        do_tick
        sleep INTERVAL_SEC
      end
    end

    def do_tick
      return unless playing?
      now  = self.current_time
      cps = self.cps
      @streams.each { |s| s.notify(now, cps) }
    rescue => err
      error(err)
    end
  end
end
