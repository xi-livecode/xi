module Xq
  class Stream
    attr_reader :clock, :pattern, :timed_ring

    def initialize(clock)
      @playing = false
      self.clock = clock
    end

    def set(pattern)
      @pattern = pattern
      @pattern_dur = pattern.duration
      @timed_ring = timed_ring_array(pattern)
      play
      self
    end
    alias_method :<, :set

    def clock=(new_clock)
      @clock.unsubscribe(self) if @clock
      new_clock.subscribe(self) if playing?
      @clock = new_clock
    end

    def playing?
      @playing
    end

    def stopped?
      !playing?
    end

    def play
      @playing = true
      @clock.subscribe(self)
      self
    end
    alias_method :start, :play

    def stop
      @playing = false
      @clock.unsubscribe(self)
      self
    end
    alias_method :pause, :play

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} clock=#{@clock.inspect} #{playing? ? :playing : :stopped}>"
    rescue => err
      puts err
    end

    def notify(time)
      return unless playing? && @timed_ring

      # FIXME This is slow, it should keep an index and keep shifting it as time passes
      mtime = time % @pattern_dur
      pos = @timed_ring.find_index { |(t, _)| t >= mtime }
      return if pos.nil?

      if pos != @old_pos
        @old_pos = pos
        events = @timed_ring[pos-1].last
        logger.info("#{Time.now} #{events}")
      end
    end

    private

    def timed_ring_array(pattern)
      h = Hash.new { |h, k| h[k] = [] }
      pattern.each do |event|
        k = event.value.keys.first
        h[event.start] << event.value
        if k == pattern.metadata[:gate]
          h[event.start] << {gate: 1}
          h[event.end]   << {gate: 0}
        end
      end
      h.sort_by { |k,_| k }.to_a
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
