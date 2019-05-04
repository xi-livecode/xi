require 'test_helper'
require 'xi/scale'

describe '#p' do
  describe Array do
    it 'creates a Pattern from an Array' do
      assert_pattern [1, 2, 3], [1, 2, 3].p
    end
  end

  describe Enumerator do
    it 'creates a Pattern from an Enumerator' do
      enum = (1..10).lazy.take(5)
      assert_pattern enum, enum.p
    end
  end

  describe Range do
    it 'creates a Pattern from a Range' do
      assert_pattern 1..7, (1..7).p
    end
  end

  describe Integer do
    it 'creates a Pattern from a Integer' do
      assert_pattern [42], 42.p
    end
  end

  describe Float do
    it 'creates a Pattern from a Float' do
      assert_pattern [3.14], 3.14.p
    end
  end

  describe String do
    it 'creates a Pattern from a String' do
      assert_pattern ['kick'], 'kick'.p
    end
  end

  describe Symbol do
    it 'creates a Pattern from a Symbol' do
      assert_pattern [:kick], :kick.p
    end
  end

  describe Rational do
    it 'creates a Pattern from a Rational' do
      assert_pattern [1/8], (1/8).p
    end
  end

  describe Hash do
    it 'creates a Pattern from a Hash' do
      h = {degree: [0,1,2], scale: [Xi::Scale.major]}
      assert_instance_of Xi::Pattern, h.p
      assert_equal [h], h.p.take_values(1)
    end
  end
end

describe Integer do
  describe '#/' do
    it 'divides number and casts it as a Rational' do
      assert_equal 1/2.to_r, 1/2
    end
  end
end

describe Numeric do
  describe '#db_to_amp' do
    it 'converts db to amp' do
      assert_equal 1/10, -20.db_to_amp
    end
  end

  describe '#degree_to_key' do
    it 'converts a degree number to key from a +scale+ and +steps_per_octave+' do
      assert_equal 4, 2.degree_to_key(Xi::Scale.major, 12)
      assert_equal 3, 2.degree_to_key(Xi::Scale.minor, 12)
    end
  end
end

describe Enumerator do
  describe '#next?' do
    it 'returns true if there is a "next" element' do
      assert [1].each.next?
      refute [].each.next?
    end
  end
end
