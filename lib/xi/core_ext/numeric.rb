module Xi::CoreExt
  module Numeric
    def midi_to_cps
      440 * (2 ** ((self - 69) / 12.0))
    end

    def db_to_amp
      10 ** (self / 20.0)
    end

    def degree_to_key(scale, steps_per_octave)
      accidental = (self - self.to_i) * 10.0
      inner_key = scale[self % scale.size]
      base_key = (self / scale.size).to_i * steps_per_octave + inner_key
      if accidental != 0
        base_key + accidental * (steps_per_octave / 12.0)
      else
        base_key
      end
    end
  end
end

class Integer
  include Xi::CoreExt::Numeric
end

class Float
  include Xi::CoreExt::Numeric
end

class Rational
  include Xi::CoreExt::Numeric
end
