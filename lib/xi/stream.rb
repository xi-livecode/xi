require 'set'

module Xi
  class Stream
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

      update_internal_structures
      play

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
      return unless playing? && @source

      @changed_params.clear
      forward_enums(now) if @must_forward

      play_enums(now)

      do_gate_off     if gate_param_changed?
      do_state_change if state_changed?
      do_gate_on      if gate_param_changed?
    end

    private

    def forward_enums(now)
      @enums.each do |p, (enum, total_dur)|
        cur_pos = now % total_dur
        next_ev = enum.peek

        while distance = (cur_pos - next_ev.start) % total_dur do
          enum.next
          break if distance <= next_ev.duration
          next_ev = enum.peek
        end
      end
      @must_forward = false
    end

    def play_enums(now)
      @enums.each do |p, (enum, total_dur)|
        cur_pos = now % total_dur
        next_ev = enum.peek

        if (cur_pos - next_ev.start) % total_dur <= WINDOW_SEC
          update_state(p, next_ev.value)
          enum.next
        end
      end
    end

    def update_internal_structures
      @new_sound_object_id = 0
      @enums = @source.map { |k, v|
        pat = v.p(@event_duration)
        [k, [infinite_enum(pat), pat.total_duration]]
      }.to_h
      @must_forward = true
    end

    def do_gate_on
      logger.info "Gate on: #{gate}"
    end

    def do_gate_off
      logger.info "Gate off: #{gate}"
    end

    def do_state_change
      logger.info "State change: #{@state.select { |k, v| @changed_params.include?(k) }.to_h}"
    end

    def update_state(p, v)
      logger.debug "Update state of :#{p}: #{v}"
      @changed_params << p if v != @state[p]
      @state[p] = v
    end

    def state_changed?
      !@changed_params.empty?
    end

    def gate_param_changed?
      @changed_params.include?(gate)
    end

    def infinite_enum(p)
      Enumerator.new { |y| loop { p.each_event { |e| y << e } } }
    end

    def logger
      # FIXME this should be configurable
      @logger ||= Logger.new("/tmp/xi.log")
    end
  end
end
