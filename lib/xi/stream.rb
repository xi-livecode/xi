require 'set'

module Xi
  class Stream
    TimedRing = Struct.new(:ring, :duration, :pos)

    attr_reader :clock, :pattern, :state, :params_tr, :gate_on_tr, :gate_off_tr

    def initialize(clock)
      @playing = false
      @state = {}
      @changed_params = [].to_set
      self.clock = clock
    end

    def set(hash)
      @new_sound_object_id = 0
      @pattern = hash.p
      @params_tr = params_timed_rings(@pattern)
      @gate_on_tr, @gate_off_tr = gate_timed_rings(@pattern)
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
      logger.error(err)
    end

    def notify(now)
      return unless playing? && @params_tr
      @changed_params.clear
      do_timed_ring_hash(@params_tr, now) { |es| update_state(es) }
      do_timed_ring_hash(@gate_off_tr, now) { |ss| do_gate_off(ss) }
      apply_state_change if state_changed?
      do_timed_ring_hash(@gate_on_tr, now) { |ss| do_gate_on(ss) }
    end

    private

    def do_gate_on(ss)
      logger.info "Gate on: #{ss}"
    end

    def do_gate_off(ss)
      logger.info "Gate off: #{ss}"
    end

    def do_timed_ring_hash(tr_h, now)
      tr_h.each do |p, tr|
        # FIXME This is slow, it should keep an index and
        # keep shifting it as time passes...
        mtime = now % tr.duration.to_f
        pos = tr.ring.find_index { |(t, _)| t >= mtime } || tr.ring.size

        next if (mtime - tr.ring[pos-1][0]) > 0.05

        if pos != tr.pos
          logger.info "mtime=#{mtime}, tr.ring[pos-1]=#{tr.ring[pos-1]}"
          tr.pos = pos
          values = tr.ring[pos-1].last
          yield values
        end
      end
    end

    def update_state(events)
      logger.info(events)
      events.each do |h|
        p, v = h.to_a.first
        @changed_params << p if v != @state[p]
        @state[p] = v
      end
    end

    def state_changed?
      !@changed_params.empty?
    end

    def apply_state_change
      logger.info "Changed parameters: #{@changed_params.to_a}"
    end

    def params_timed_rings(pattern)
      events_per_params(pattern).map { |p, events|
        tr = TimedRing.new

        # Create timed ring for events
        e = events.max_by(&:start)
        tr.duration = e.start + e.duration

        h = Hash.new { |h, k| h[k] = [] }
        events.each do |event|
          h[event.start] << event.value
        end
        tr.ring = h.sort_by { |k, _| k }.to_a

        [p, tr]
      }.to_h
    end

    def gate_timed_rings(pattern)
      # Build Gate on and gate off timed rings
      gate_on_tr = {}
      gate_off_tr = {}
      so_id = @new_sound_object_id

      evs = events_per_params(pattern).select do |p, _|
        p == pattern.metadata[:gate]
      end

      evs.each do |p, events|
        tr_on = TimedRing.new
        tr_off = TimedRing.new

        # Create timed ring for events
        e = events.max_by(&:start)
        tr_on.duration = e.start + e.duration
        tr_off.duration = tr_on.duration

        h_on = Hash.new { |h, k| h[k] = [] }
        h_off = Hash.new { |h, k| h[k] = [] }

        events.each do |event|
          h_on[event.start] << so_id
          h_off[event.end] << so_id
          so_id += 1
        end

        tr_on.ring = h_on.sort_by { |k, _| k }.to_a
        tr_off.ring = h_off.sort_by { |k, _| k }.to_a

        gate_on_tr[p] = tr_on
        gate_off_tr[p] = tr_off
      end

      @new_sound_object_id = so_id

      [gate_on_tr, gate_off_tr]
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
