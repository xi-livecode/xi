require 'forwardable'

class Xi::Scale
  extend Forwardable

  DEGREES = {
    # TWELVE TONES PER OCTAVE
    # 5 note scales
    minorPentatonic: [0,3,5,7,10],
    majorPentatonic: [0,2,4,7,9],
    # another mode of major pentatonic
    ritusen: [0,2,5,7,9],
    # another mode of major pentatonic
    egyptian: [0,2,5,7,10],

    kumoi: [0,2,3,7,9],
    hirajoshi: [0,2,3,7,8],

    iwato: [0,1,5,6,10],    # mode of hirajoshi
    chinese: [0,4,6,7,11],  # mode of hirajoshi
    indian: [0,4,5,7,10],
    pelog: [0,1,3,7,8],

    prometheus: [0,2,4,6,11],
    scriabin: [0,1,4,7,9],

    # han chinese pentatonic scales
    gong: [0,2,4,7,9],
    shang: [0,2,5,7,10],
    jiao: [0,3,5,8,10],
    zhi: [0,2,5,7,9],
    yu: [0,3,5,7,10],

    # 6 note scales
    whole: [0, 2, 4, 6, 8, 10],
    augmented: [0,3,4,7,8,11],
    augmented2: [0,1,4,5,8,9],

    # hexatonic modes with no tritone
    hexMajor7: [0,2,4,7,9,11],
    hexDorian: [0,2,3,5,7,10],
    hexPhrygian: [0,1,3,5,8,10],
    hexSus: [0,2,5,7,9,10],
    hexMajor6: [0,2,4,5,7,9],
    hexAeolian: [0,3,5,7,8,10],

    # 7 note scales
    major: [0,2,4,5,7,9,11],
    ionian: [0,2,4,5,7,9,11],
    dorian: [0,2,3,5,7,9,10],
    phrygian: [0,1,3,5,7,8,10],
    lydian: [0,2,4,6,7,9,11],
    mixolydian: [0,2,4,5,7,9,10],
    aeolian: [0,2,3,5,7,8,10],
    minor: [0,2,3,5,7,8,10],
    locrian: [0,1,3,5,6,8,10],

    harmonicMinor: [0,2,3,5,7,8,11],
    harmonicMajor: [0,2,4,5,7,8,11],

    melodicMinor: [0,2,3,5,7,9,11],
    melodicMinorDesc: [0,2,3,5,7,8,10],
    melodicMajor: [0,2,4,5,7,8,10],

    bartok: [0,2,4,5,7,8,10],
    hindu: [0,2,4,5,7,8,10],

    # raga modes
    todi: [0,1,3,6,7,8,11],
    purvi: [0,1,4,6,7,8,11],
    marva: [0,1,4,6,7,9,11],
    bhairav: [0,1,4,5,7,8,11],
    ahirbhairav: [0,1,4,5,7,9,10],

    superLocrian: [0,1,3,4,6,8,10],
    romanianMinor: [0,2,3,6,7,9,10],
    hungarianMinor: [0,2,3,6,7,8,11],
    neapolitanMinor: [0,1,3,5,7,8,11],
    enigmatic: [0,1,4,6,8,10,11],
    spanish: [0,1,4,5,7,8,10],

    # modes of whole tones with added note ->
    leadingWhole: [0,2,4,6,8,10,11],
    lydianMinor: [0,2,4,6,7,8,10],
    neapolitanMajor: [0,1,3,5,7,9,11],
    locrianMajor: [0,2,4,5,6,8,10],

    # 8 note scales
    diminished: [0,1,3,4,6,7,9,10],
    diminished2: [0,2,3,5,6,8,9,11],

    # 12 note scales
    chromatic: (0..11).to_a,
  }

  class << self
    DEGREES.each do |name, list|
      define_method(name) { self.new(list) }
    end
  end

  attr_reader :notes

  def initialize(notes)
    @notes = notes
  end

  def_delegators :@notes, :size, :[], :to_a, :first

  def p(*delta, **metadata)
    [@notes].p(*delta, **metadata)
  end

  #def size
    #@notes.size
  #end
end
