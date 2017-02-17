require 'set'
require 'xi/music_parameters'

module Xi
  class Stream
    prepend MusicParameters

    attr_reader :clock, :opts, :source, :state, :event_duration, :gate

    def initialize(name, clock, **opts)
      @name = name.to_sym
      @opts = opts

      @mutex = Mutex.new
      @playing = false
      @last_sound_object_id = 0
      @state = {}
      @changed_params = [].to_set
      @playing_sound_objects = {}
      @prev_end = {}

      self.clock = clock
    end

    def set(event_duration: nil, gate: nil, **source)
      @mutex.synchronize do
        source[:s] ||= @name
        @source = source
        @gate = gate if gate
        @event_duration = event_duration if event_duration
        update_internal_structures
      end
      play
      self
    end
    alias_method :call, :set

    def event_duration=(new_value)
      @mutex.synchronize do
        @event_duration = new_value
        update_internal_structures
      end
    end

    def gate=(new_value)
      @mutex.synchronize do
        @gate = new_value
        update_internal_structures
      end
    end

    def clock=(new_clock)
      @clock.unsubscribe(self) if @clock
      new_clock.subscribe(self) if playing?
      @clock = new_clock
    end

    def playing?
      @mutex.synchronize { @playing }
    end

    def stopped?
      !playing?
    end

    def play
      @mutex.synchronize do
        @playing = true
        @clock.subscribe(self)
      end
      self
    end
    alias_method :start, :play

    def stop
      @mutex.synchronize do
        @playing = false
        @state.clear
        @clock.unsubscribe(self)
      end
      self
    end
    alias_method :pause, :play

    def inspect
      "#<#{self.class.name} :#{@name} " \
        "#{playing? ? :playing : :stopped} at #{@clock.cps}cps" \
        "#{" #{@opts}" if @opts.any?}>"
    rescue => err
      error(err)
    end

    def notify(now)
      return unless playing? && @source

      @mutex.synchronize do
        @changed_params.clear

        forward_enums(now) if @must_forward
        gate_off = gate_off_old_sound_objects(now)
        gate_on = play_enums(now)

        # Call hooks
        do_gate_off_change(gate_off) unless gate_off.empty?
        do_state_change if state_changed?
        do_gate_on_change(gate_on) unless gate_on.empty?
      end
    end

    private

    def changed_state
      @state.select { |k, _| @changed_params.include?(k) }
    end

    def forward_enums(now)
      @enums.each do |p, (enum, total_dur)|
        next if total_dur == 0

        cur_pos = now % total_dur
        start_pos = now - cur_pos

        loop do
          next_ev = enum.peek
          distance = (cur_pos - next_ev.start) % total_dur

          @prev_end[p] = start_pos + next_ev.end
          enum.next

          break if distance <= next_ev.duration
        end
      end

      @must_forward = false
    end

    def gate_off_old_sound_objects(now)
      gate_off = []

      # Check if there are any currently playing sound objects that
      # must be gated off
      @playing_sound_objects.dup.each do |end_pos, h|
        if now >= h[:at] - latency_sec
          gate_off << h
          @playing_sound_objects.delete(end_pos)
        end
      end

      gate_off
    end

    def play_enums(now)
      gate_on = []

      @enums.each do |p, (enum, total_dur)|
        next if total_dur == 0

        cur_pos = now % total_dur
        start_pos = now - cur_pos

        next_ev = enum.peek

        # Do we need to play next event now? If not, skip this parameter
        if (@prev_end[p].nil? || now >= @prev_end[p]) && cur_pos >= next_ev.start - latency_sec
          # Update state based on pattern value
          # TODO: Pass as parameter exact time (start_ts + next_ev.start)
          update_state(p, next_ev.value)
          transform_state

          # If a gate parameter changed, create a new sound object
          if p == @gate
            new_so_ids = Array(next_ev.value)
              .size.times.map { new_sound_object_id }

            gate_on << {
              so_ids: new_so_ids,
              at: start_pos + next_ev.start
            }

            @playing_sound_objects[rand(100000)] = {
              so_ids: new_so_ids,
              duration: total_dur,
              at: start_pos + next_ev.end,
            }
          end

          # Because we already processed event, advance enumerator
          next_ev = enum.next
          @prev_end[p] = start_pos + next_ev.end
        end
      end

      gate_on
    end

    # @override
    def transform_state
    end

    def new_sound_object_id
      @last_sound_object_id += 1
    end

    def update_internal_structures
      @must_forward = true
      @enums = @source.map { |k, v|
        pat = v.p(@event_duration)
        [k, [enum_for(:loop_events, pat), pat.total_duration]]
      }.to_h
    end

    def do_gate_on_change(ss)
      debug "Gate on change: #{ss}"
    end

    def do_gate_off_change(ss)
      debug "Gate off change: #{ss}"
    end

    def do_state_change
      debug "State change: #{@state
        .select { |k, v| @changed_params.include?(k) }.to_h}"
    end

    def update_state(p, v)
      if v != @state[p]
        debug "Update state of :#{p}: #{v}"
        @changed_params << p
        @state[p] = v
      end
    end

    def state_changed?
      !@changed_params.empty?
    end

    def loop_events(pattern)
      loop { pattern.each_event { |e| yield e } }
    end

    def latency_sec
      0.05
    end
  end
end
