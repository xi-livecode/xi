require 'set'

module Xi
  class Stream
    TimedRing = Struct.new(:ring, :duration, :pos)

    WINDOW_SEC = 0.05

    attr_reader :clock, :source, :source_patterns, :state, :event_duration, :gate

    def initialize(clock)
      @playing = false
      @state = {}
      @changed_params = [].to_set

      self.clock = clock
    end

    def set(event_duration: nil, gate: nil, **source)
      @source = source
      @gate = gate if gate
      @event_duration = event_duration if event_duration

      #update_internal_structures
      #play
      self
    end
    alias_method :<<, :set

    def event_duration=(new_value)
      @event_duration = new_value
      update_internal_structures
    end

    def gate=(new_value)
      @gate = new_value
      update_internal_structures
    end

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
      do_timed_ring_hash(@params_tr, now) { |p, es| update_state(p, es) }
      do_timed_ring_hash(@gate_off_tr, now) { |_, ss| do_gate_off(ss) }
      apply_state_change if state_changed?
      do_timed_ring_hash(@gate_on_tr, now) { |_, ss| do_gate_on(ss) }
    end

    private

    def update_internal_structures
      @new_sound_object_id = 0
      @source_patterns = @source.map { |k, v| [k, v.p(@dur)] }.to_h
      @params_tr = params_timed_rings(@source_patterns)
      @gate_on_tr, @gate_off_tr = gate_timed_rings(@source_patterns, @gate)
    end

    def do_gate_on(ss)
      logger.info "Gate on: #{ss}"
    end

    def do_gate_off(ss)
      logger.info "Gate off: #{ss}"
    end

    def do_timed_ring_hash(tr_h, now)
      tr_h.each do |p, tr|
        mtime = now % tr.duration.to_f
        # FIXME Avoid find_index, keep an index and move it when necessary
        pos = tr.ring.find_index { |(t, _)| t >= mtime } || tr.ring.size

        next if (mtime - tr.ring[pos-1][0]) > WINDOW_SEC

        if pos != tr.pos
          logger.info "mtime=#{mtime}, tr.ring[pos-1]=#{tr.ring[pos-1]}"
          tr.pos = pos
          values = tr.ring[pos-1].last
          yield p, values
        end
      end
    end

    def update_state(p, values)
      logger.info("#{p} => #{values}")
      values.each do |v|
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

    def params_timed_rings(params_pattern)
      params_pattern.map { |p, pattern|
        # Create timed ring for events
        tr = TimedRing.new
        tr.duration = pattern.total_duration

        ring = Hash.new { |h, k| h[k] = [] }
        pattern.each do |event|
          ring[event.start] << event.value
        end
        tr.ring = ring.sort_by { |k, _| k }.to_a

        [p, tr]
      }.to_h
    end

    def gate_timed_rings(params_pattern, gate_param)
      # Build Gate on and gate off timed rings
      gate_on_tr = {}
      gate_off_tr = {}
      so_id = @new_sound_object_id

      params_pattern.select { |p, _| p == gate_param }.each do |p, pattern|
        # Create timed ring for events
        tr_on = TimedRing.new
        tr_off = TimedRing.new

        tr_on.duration = pattern.total_duration
        tr_off.duration = pattern.total_duration

        h_on = Hash.new { |h, k| h[k] = [] }
        h_off = Hash.new { |h, k| h[k] = [] }

        pattern.each do |e|
          h_on[e.start] << so_id
          h_off[e.end] << so_id
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

    def logger
      # FIXME this should be configurable
      @logger ||= Logger.new("/tmp/xi.log")
    end
  end
end
