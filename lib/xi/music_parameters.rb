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
        @state[:note] = note_from(@state[:degree], @state[:scale],
                                  @state[:steps_per_octave])
        @changed_params << :note
      end

      if !changed_param?(:midinote) && changed_param?(:note)
        @state[:midinote] = midinote_from(@state[:note], @state[:root],
                                          @state[:octave],
                                          @state[:steps_per_octave])
        @changed_params << :midinote
      end
    end

    def midinote_from(note, root, octave, steps_per_octave)
      Array(note).compact.map { |n|
        root.to_i + octave.to_i * steps_per_octave + n
      }
    end

    def note_from(degree, scale, steps_per_octave)
      Array(degree).compact.map do |d|
        d.degree_to_key(Array(scale), steps_per_octave)
      end
    end

    def changed_param?(*params)
      @changed_params.any? { |p| params.include?(p) }
    end
  end
end
