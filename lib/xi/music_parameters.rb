require 'xi/scale'

class Xi::Stream
  module MusicParameters
    DEFAULT = {
      degree: 0,
      octave: 5,
      root:   0,
      scale:  Xi::Scale.major,
      steps_per_octave: 12,
    }

    private

    def transform_state
      super

      @state = DEFAULT.merge(@state)

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
  end
end
