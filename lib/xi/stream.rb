module Xi
  class Stream
    TimedRing = Struct.new(:ring, :duration, :pos)

    attr_reader :clock, :pattern, :state

    def initialize(clock)
      @playing = false
      @state = {}
      self.clock = clock
    end

    def set(hash)
      @pattern = hash.p
      @timed_rings_per_params = build_timed_rings(@pattern)
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
      @state.clear
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
      return unless playing? && @timed_rings_per_params

      # FIXME This is slow, it should keep an index and
      # keep shifting it as time passes...
      @timed_rings_per_params.each do |p, tr|
        mtime = time % tr.duration.to_f
        pos = tr.ring.find_index { |(t, _)| t >= mtime } || tr.ring.size
        return if pos.nil?

        if pos != tr.pos
          tr.pos = pos
          events = tr.ring[pos-1].last
          play_events(events)
        end
      end
    end

    private

    def play_events(events)
      logger.info(events)
      events.each do |h|
        p, v = h.to_a.first
        if p == :gate && v != @state[p]
          logger.info("Gate #{v == 1 ? 'on' : 'off'}")
        end
        @state[p] = v
      end
    end

    def build_timed_rings(pattern)
      events_per_params(pattern).map { |param, events|
        res = TimedRing.new

        e = events.max_by(&:start)
        res.duration = e.start + e.duration

        h = Hash.new { |h, k| h[k] = [] }
        events.each do |event|
          k = event.value.keys.first
          h[event.start] << event.value
          if k == pattern.metadata[:gate]
            h[event.start] << {gate: 1}
            h[event.end]   << {gate: 0}
          end
        end
        res.ring = h.sort_by { |k,_| k }.to_a

        [param, res]
      }.to_h
    end

    def events_per_params(pattern)
      pattern.group_by { |e| e.value.keys.first }
    end

    def logger
      # FIXME this should be configurable
      @logger ||= Logger.new("/tmp/xi.log")
    end
  end
end
