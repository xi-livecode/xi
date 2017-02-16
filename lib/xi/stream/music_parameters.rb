require 'xi/scale'

class Xi::Stream
  module MusicParameters
    DEFAULT_PARAMS = {
      degree: 0,
      octave: 5,
      root: 0,
      scale: Xi::Scale.major,
    }
    STEPS_PER_OCTAVE = 12

    private

    def transform_state
      super

      @state = DEFAULT_PARAMS.merge(@state)

      if !changed_param?(:note) && changed_param?(:degree, :scale)
        @state[:note] = note_from(@state[:degree], @state[:scale])
        @changed_params << :note
      end

      if changed_param?(:note) && !changed_param?(:midinote)
        @state[:midinote] = midinote_from(@state[:note], @state[:root], @state[:octave])
        @changed_params << :midinote
      end
    end

    def midinote_from(note, root, octave)
      Array(note).compact.map { |n|
        root.to_i + octave.to_i * STEPS_PER_OCTAVE + n
      }
    end

    def note_from(degree, scale)
      scale ||= DEFAULT_PARAMS[:scale]
      Array(degree).compact.map do |d|
        d.degree_to_key(Array(scale), STEPS_PER_OCTAVE)
      end
    end

    def changed_param?(*params)
      @changed_params.any? { |p| params.include?(p) }
    end
  end
end
