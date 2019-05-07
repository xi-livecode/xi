require 'xi/scale'
require 'set'

module Xi
  class Stream
    attr_reader :clock, :opts, :source, :state, :delta, :gate

    DEFAULT_PARAMS = {
      degree: 0,
      octave: 5,
      root:   0,
      scale:  Xi::Scale.major,
      steps_per_octave: 12,
    }

    def initialize(name, clock, **opts)
      Array(opts.delete(:include)).each { |m| include_mixin(m) }

      @name = name.to_sym
      @opts = opts

      @mutex = Mutex.new
      @playing = false
      @last_sound_object_id = 0
      @state = {}
      @changed_params = [].to_set
      @playing_sound_objects = {}
      @prev_ts = {}
      @prev_delta = {}

      self.clock = clock
    end

    def set(delta: nil, gate: nil, **source)
      @mutex.synchronize do
        remove_parameters_from_prev_source(source)
        @source = source
        @gate = gate || parameter_with_smallest_delta(source)
        @delta = delta if delta
        @reset = true unless @playing
        update_internal_structures
      end
      play
      self
    end
    alias_method :call, :set

    def delta=(new_value)
      @mutex.synchronize do
        @delta = new_value
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
        @prev_ts.clear
        @prev_delta.clear
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

    def notify(now, cps)
      return unless playing? && @source

      @mutex.synchronize do
        @changed_params.clear

        update_all_state if @reset

        gate_off = gate_off_old_sound_objects(now)
        gate_on = play_enums(now, cps)

        # Call hooks
        do_gate_off_change(gate_off) unless gate_off.empty?
        do_state_change if state_changed?
        do_gate_on_change(gate_on) unless gate_on.empty?
      end
    end

    private

    def include_mixin(module_or_name)
      mod = if module_or_name.is_a?(Module)
        module_or_name
      else
        name = module_or_name.to_s
        require "#{self.class.name.underscore}/#{name}"
        self.class.const_get(name.camelize)
      end
      singleton_class.send(:include, mod)
    end

    def changed_state
      @state.select { |k, _| @changed_params.include?(k) }
    end

    def gate_off_old_sound_objects(now)
      gate_off = []

      # Check if there are any currently playing sound objects that
      # must be gated off
      @playing_sound_objects.dup.each do |start_pos, h|
        if now + @clock.init_ts >= h[:at] - latency_sec
          gate_off << h
          @playing_sound_objects.delete(start_pos)
        end
      end

      gate_off
    end

    def play_enums(now, cps)
      gate_on = []

      @enums.each do |p, enum|
        next unless enum.next?

        n_value, n_start, n_dur = enum.peek

        @prev_ts[p]    ||= n_start / cps
        @prev_delta[p] ||= n_dur

        next_start = @prev_ts[p] + (@prev_delta[p] / cps)

        # Do we need to play next event? If not, skip this parameter value
        if now >= next_start - latency_sec
          # If it is too late to play this event, skip it
          if now < next_start
            starts_at = @clock.init_ts + next_start

            # Update state based on pattern value
            # TODO: Pass as parameter exact time: starts_at
            update_state(p, n_value)
            transform_state

            # If a gate parameter changed, create a new sound object
            if p == @gate
              # If these sounds objects are new,
              # consider them as new "gate on" events.
              unless @playing_sound_objects.key?(n_start)
                new_so_ids = Array(n_value)
                  .size.times.map { new_sound_object_id }

                gate_on << {so_ids: new_so_ids, at: starts_at}
                @playing_sound_objects[n_start] = {so_ids: new_so_ids}
              end

              # Set (or update) ends_at timestamp
              legato = @state[:legato] || 1
              ends_at = @clock.init_ts + next_start + ((n_dur * legato) / cps)
              @playing_sound_objects[n_start][:at] = ends_at
            end
          end

          @prev_ts[p]    = next_start
          @prev_delta[p] = n_dur

          # Because we already processed event, advance enumerator
          enum.next
        end
      end

      gate_on
    end

    def transform_state
      @state = DEFAULT_PARAMS.merge(@state)

      @state[:s] ||= @name

      if !changed_param?(:note) && changed_param?(:degree, :scale, :steps_per_octave)
        @state[:note] = reduce_to_note
        @changed_params << :note
      end

      if !changed_param?(:midinote) && changed_param?(:note)
        @state[:midinote] = reduce_to_midinote
        @changed_params << :midinote
      end
    end

    def reduce_to_midinote
      Array(@state[:note]).compact.map { |n|
        @state[:root].to_i + @state[:octave].to_i * @state[:steps_per_octave] + n
      }
    end

    def reduce_to_note
      Array(@state[:degree]).compact.map do |d|
        d.degree_to_key(Array(@state[:scale]), @state[:steps_per_octave])
      end
    end

    def changed_param?(*params)
      @changed_params.any? { |p| params.include?(p) }
    end

    def new_sound_object_id
      @last_sound_object_id += 1
    end

    def update_internal_structures
      cycle = @clock.current_cycle
      @enums = @source.map { |k, v| [k, v.p(@delta).each_event(cycle)] }.to_h
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

    def update_state(param, value)
      kv = value.is_a?(Hash) ? value : {param => value}
      kv.each do |k, v|
        if v != @state[k]
          debug "Update state of :#{k}: #{v}"
          @changed_params << k
          @state[k] = v
        end
      end
    end

    def state_changed?
      !@changed_params.empty?
    end

    def update_all_state
      @enums.each do |p, enum|
        n_value, _ = enum.peek
        update_state(p, n_value)
      end
      transform_state
      @reset = false
    end

    def parameter_with_smallest_delta(source)
      source.min_by { |param, enum|
        delta = enum.p.delta
        delta.is_a?(Array) ? delta.min : delta
      }.first
    end

    def remove_parameters_from_prev_source(new_source)
      (@source.keys - new_source.keys).each { |k| @state.delete(k) } unless @source.nil?
    end

    def latency_sec
      0.05
    end
  end
end
