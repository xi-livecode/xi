require 'xi/stream'
require 'xi/osc'
require 'set'

module Xi::Supercollider
  class Stream < Xi::Stream
    include Xi::OSC

    MAX_NODE_ID = 10000
    DEFAULT_PARAMS = {
      out:  0,
      amp:  1.0,
      pan:  0.0,
      vel:  127,
    }

    def initialize(name, clock, server: 'localhost', port: 57110, base_node_id: 2000, **opts)
      super

      @base_node_id = base_node_id
      @playing_synths = [].to_set
      at_exit { free_playing_synths }
    end

    def stop
      @mutex.synchronize do
        @playing_synths.each do |so_id|
          n_set(node_id(so_id), gate: 0)
        end
      end
      super
    end

    def free_playing_synths
      n_free(*@playing_synths.map { |so_id| node_id(so_id) })
    end

    def node_id(so_id)
      (@base_node_id + so_id) % MAX_NODE_ID
    end

    private

    def transform_state
      super

      @state = DEFAULT_PARAMS.merge(@state)

      if changed_param?(:db) && !changed_param?(:amp)
        @state[:amp] = @state[:db].db_to_amp
        @changed_params << :amp
      end

      if changed_param?(:midinote) && !changed_param?(:freq)
        @state[:freq] = Array(@state[:midinote]).map(&:midi_to_cps)
        @changed_params << :freq
      end
    end

    def do_gate_on_change(changes)
      debug "Gate on change: #{changes}"

      name = @state[:s] || :default
      state_params = @state.reject { |k, _| %i(s).include?(k) }

      freq = Array(state_params[:freq])

      changes.each do |change|
        at = Time.at(change.fetch(:at))

        change.fetch(:so_ids).each.with_index do |so_id, i|
          freq_i = freq.size > 0 ? freq[i % freq.size] : nil

          s_new(name, node_id(so_id), **state_params, gate: 1, freq: freq_i, at: at)
          @playing_synths << so_id
        end
      end
    end

    def do_gate_off_change(changes)
      debug "Gate off change: #{changes}"

      changes.each do |change|
        at = Time.at(change.fetch(:at))

        change.fetch(:so_ids).each do |so_id|
          n_set(node_id(so_id), gate: 0, at: at)
          @playing_synths.delete(so_id)
        end
      end
    end

    def do_state_change
      debug "State change: #{changed_state}"
      @playing_synths.each do |so_id|
        n_set(node_id(so_id), **changed_state)
      end
    end

    def n_set(id, at: Time.now, **args)
      send_bundle('/n_set', id, *osc_args(args), at: at)
    end

    def s_new(name, id, add_action: 0, target_id: 1, at: Time.now, **args)
      send_bundle('/s_new', name.to_s, id.to_i, add_action.to_i,
                  target_id.to_i, *osc_args(args), at: at)
    end

    def n_free(*ids, at: Time.now)
      send_bundle('/n_free', *ids, at: at)
    end

    def osc_args(**args)
      args.map { |k, v| [k.to_s, coerce_osc_value(v)] }.flatten(1)
    end

    def coerce_osc_value(value)
      v = Array(value).first
      v = v.to_f if v.is_a?(Rational)
      v = v.to_i if !v.is_a?(Float) && !v.is_a?(String) && !v.is_a?(Symbol)
      v
    end
  end
end
