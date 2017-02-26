require 'test_helper'

describe Xi::Pattern do
  describe '#new' do
    it 'takes an array as +source+' do
      @p = Xi::Pattern.new([1, 2, 3])

      assert_instance_of Xi::Pattern, @p
      assert_equal [1, 2, 3], @p.source
    end

    it 'takes a block as +source+' do
      @p = Xi::Pattern.new { |y|
        y << 1
        y << [10, 20]
        y << :foo
      }

      assert_instance_of Xi::Pattern, @p
      assert_instance_of Proc, @p.source
      assert_equal [1, [10, 20], :foo], @p.take_values(3)
    end

    it 'takes a block as +source+ that yields [v, s, d]' do
      @p = Xi::Pattern.new(delta: 1/2) { |y, d|
        (1..inf).each { |v| y << v }
      }

      assert_instance_of Xi::Pattern, @p
      assert_instance_of Proc, @p.source
      assert_equal (1..10).to_a, @p.take_values(10)
    end

    it 'takes a Pattern instance as +source+' do
      p1 = Xi::Pattern.new([1, 2, 3])
      @p = Xi::Pattern.new(p1)

      assert_instance_of Xi::Pattern, @p
      assert_equal p1, @p.source
      assert_equal [1, 2, 3], @p.take_values(3)
    end

    it 'accepts +delta+, which defaults to 1' do
      @p = Xi::Pattern.new([1])
      assert_equal 1, @p.delta

      @p = Xi::Pattern.new([1], delta: 1/4)
      assert_equal 1/4, @p.delta
    end

    it 'accepts metadata as keyword arguments' do
      @p = Xi::Pattern.new([1], delta: 1/2, foo: :bar)

      assert_equal 1/2, @p.delta
      assert_equal({foo: :bar}, @p.metadata)
    end

    it 'raises ArgumentError if neither source or block are provided' do
      assert_raises(ArgumentError) do
        @p = Xi::Pattern.new
      end
    end

    it 'raises ArgumentError if delta is infinite' do
      assert_raises(ArgumentError) do
        @p = Xi::Pattern.new([1, 2, 3], delta: (1..inf))
      end

      assert_raises(ArgumentError) do
        @p = Xi::Pattern.new([1, 2, 3], delta: P.series)
      end
    end
  end

  describe '.[]' do
    it 'constructs a new Pattern, same as .new' do
      assert_equal Xi::Pattern[1,2,3],
                   Xi::Pattern.new([1,2,3])

      assert_equal Xi::Pattern[1,2,3, delta: 1/2],
                   Xi::Pattern.new([1,2,3], delta: 1/2)

      assert_equal Xi::Pattern[1,2,3, delta: 1/2, gate: :note],
                   Xi::Pattern.new([1,2,3], delta: 1/2, gate: :note)
    end
  end

  describe '#p' do
    before do
      @p = Xi::Pattern.new([1], delta: 2, baz: 1)
    end

    it 'returns a new Pattern with the same source' do
      assert_equal @p.p.source.object_id, @p.source.object_id
    end

    it 'accepts delta values as first parameter, and overrides original' do
      assert_equal 2, @p.delta
      assert_equal 1/2, @p.p(1/2).delta
      assert_equal [1/4, 1/8, 1/16], @p.p(1/4, 1/8, 1/16).delta
      assert_equal P[1,2,3], @p.p(P[1,2,3]).delta
    end

    it 'accepts metadata as keyword arguments, and is merged with original' do
      assert_equal({baz: 1}, @p.metadata)
      assert_equal({foo: :bar, baz: 1}, @p.p(foo: :bar).metadata)
    end
  end

  describe '#finite? and #infinite?' do
    it 'returns true or false whether pattern has a finite or infinite size' do
      @p = Xi::Pattern.new(1..10)
      assert @p.finite?
      refute @p.infinite?

      @p = Xi::Pattern.new { |y| y << rand }
      refute @p.finite?
      assert @p.infinite?

      @p = Xi::Pattern.new(size: 4) { |y| y << rand }
      assert @p.finite?
      refute @p.infinite?

      @p = Xi::Pattern.new(1..inf)
      refute @p.finite?
      assert @p.infinite?
    end
  end

  describe '#each_event' do
    describe 'with no block' do
      it 'returns an Enumerator' do
        assert_instance_of Enumerator, [].p.each_event
      end
    end

    describe 'when source responds to #call (e.g. a block)' do
      it 'yields events and current iteration' do
        @p = Xi::Pattern.new(size: 3) { |y| (1..3).each { |v| y << v } }

        assert_equal [[1, 0, 1, 0],
                      [2, 1, 1, 0],
                      [3, 2, 1, 0],
                      [1, 3, 1, 1]], @p.each_event.take(4)

        assert_equal [[1, 3, 1, 1],
                      [2, 4, 1, 1],
                      [3, 5, 1, 1],
                      [1, 6, 1, 2]], @p.each_event(2.97).take(4)
      end
    end

    describe 'when source responds to #[] and #size (e.g. an Array)' do
      it 'yields events and current iteration' do
        @p = Xi::Pattern.new([1, 2], delta: 1/4)

        assert_equal [[1,   0, 1/4, 0],
                      [2, 1/4, 1/4, 0],
                      [1, 1/2, 1/4, 1],
                      [2, 3/4, 1/4, 1]], @p.each_event.take(4)

        assert_equal [[2, 1/4, 1/4, 0],
                      [1, 1/2, 1/4, 1],
                      [2, 3/4, 1/4, 1],
                      [1,   1, 1/4, 2]], @p.each_event(0.1).take(4)

        assert_equal [[1, 1/2, 1/4, 1],
                      [2, 3/4, 1/4, 1],
                      [1,   1, 1/4, 2],
                      [2, 5/4, 1/4, 2]], @p.each_event(1/4 + 0.1).take(4)

        @p = Xi::Pattern.new([:a, :b, :c], delta: [1/2, 1/4])

        assert_equal [[:b,    42, 1/2, 18],
                      [:c,  85/2, 1/4, 18],
                      [:a, 171/4, 1/2, 19],
                      [:b, 173/4, 1/4, 19]], @p.each_event(42).take(4)
      end
    end

    describe 'when source responds to #each_event (e.g. a Pattern)' do
      it 'yields events and current iteration' do
        @p = Xi::Pattern.new([1, 2].p, delta: 1/4)

        assert_equal [[1, 1/2, 1/4, 1],
                      [2, 3/4, 1/4, 1],
                      [1,   1, 1/4, 2],
                      [2, 5/4, 1/4, 2]], @p.each_event(1/4 + 0.1).take(4)
      end
    end
  end

  describe '#each_delta' do
    describe 'with no block' do
      it 'returns an Enumerator' do
        assert_instance_of Enumerator, [].p.each_delta
      end
    end

    describe 'when delta is an Array' do
      it 'yields next delta value for current +iteration+' do
        @p = Xi::Pattern.new(%i(a b c), delta: [1, 2, 3])

        assert_equal [1, 2, 3, 1], @p.each_delta.take(4)
        assert_equal [2, 3, 1, 2], @p.each_delta(1).take(4)
        assert_equal [2, 3, 1, 2], @p.each_delta(1.9).take(4)
        assert_equal [3, 1, 2, 3], @p.each_delta(2).take(4)
      end
    end

    describe 'when delta is a Pattern' do
      it 'yields next delta value for current +iteration+' do
        @p = Xi::Pattern.new(%i(a b c), delta: [1/2, 1/4].p * 2)

        assert_equal [1, 1/2, 1, 1/2], @p.each_delta.take(4)
        assert_equal [1/2, 1, 1/2, 1], @p.each_delta(1).take(4)
      end
    end

    describe 'when delta is a Numeric' do
      it 'yields next delta value for current +iteration+' do
        @p = Xi::Pattern.new(%i(a b c), delta: 2)

        assert_equal [2, 2, 2], @p.each_delta.take(3)
        assert_equal [2, 2, 2], @p.each_delta(1).take(3)
      end
    end
  end

  describe '#each' do
    it 'returns an Enumerator if block is not present' do
      assert_instance_of Enumerator, [].p.each
    end

    it 'returns all values from the first iteration' do
      @p = Xi::Pattern.new([1, 2, 3])
      assert_equal [1, 2, 3], @p.each.to_a

      @p = [1, 2, 3].p + [4, 5, 6].p
      assert_equal [1, 2, 3, 4, 5, 6], @p.each.to_a
    end
  end

  describe '#reverse_each' do
    it 'returns an Enumerator if block is not present' do
      assert_instance_of Enumerator, [].p.each
    end

    it 'returns all values from the first iteration in reverse order' do
      @p = Xi::Pattern.new([1, 2, 3])
      assert_equal [3, 2, 1], @p.reverse_each.to_a

      @p = [1, 2, 3].p + [4, 5, 6].p
      assert_equal [6, 5, 4, 3, 2, 1], @p.reverse_each.to_a
    end
  end

  describe '#to_a' do
    it 'returns an Array of values from the first iteration' do
      assert_equal [1, 2, 3], Xi::Pattern.new([1, 2, 3]).to_a
    end

    it 'raises an error if pattern is infinite' do
      assert_raises(StandardError) do
        Xi::Pattern.new(1..inf).to_a
      end
    end
  end

  describe '#to_events' do
    it 'returns an Array of events from the first iteration' do
      assert_equal [[1, 0, 1, 0],
                    [2, 1, 1, 0],
                    [3, 2, 1, 0]], Xi::Pattern.new([1, 2, 3]).to_events
    end

    it 'raises an error if pattern is infinite' do
      assert_raises(StandardError) do
        Xi::Pattern.new(1..inf).to_events
      end
    end
  end

  describe '#map' do
    before do
      @p = Xi::Pattern.new([:a, :b], delta: 1/2)
    end

    it 'returns a new Pattern with events mapped to the block' do
      new_p = @p.map { |v, s, d, i| "#{v}#{(s * 10).to_i}" }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [["a0",0,1/2,0], ["b5",1/2,1/2,0]], new_p.to_events
    end

    it 'is an alias of #collect' do
      assert_equal [["a0",0,1/2,0], ["b5",1/2,1/2,0]],
        @p.collect { |v, s, d, i| "#{v}#{(s * 10).to_i}" }.to_events
    end
  end

  describe '#select' do
    before do
      @p = Xi::Pattern.new((1..4).to_a)
    end

    it 'returns a new Pattern with events selected from the block' do
      new_p = @p.select { |v| v % 2 == 0 }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [[2, 0, 1, 0],
                    [4, 1, 1, 0],
                    [2, 2, 1, 0],
                    [4, 3, 1, 0]], new_p.to_events
    end

    it 'is an alias of #find_all' do
      assert_equal [[2, 0, 1, 0],
                    [4, 1, 1, 0],
                    [2, 2, 1, 0],
                    [4, 3, 1, 0]], @p.find_all { |v| v % 2 == 0 }.to_events
    end
  end

  describe '#reject' do
    before do
      @p = Xi::Pattern.new((1..4).to_a)
    end

    it 'returns a new Pattern with events rejected from the block' do
      new_p = @p.reject { |v| v % 2 == 0 }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [[1, 0, 1, 0],
                    [3, 1, 1, 0],
                    [1, 2, 1, 0],
                    [3, 3, 1, 0]], new_p.to_events
    end
  end

  describe '#take' do
    before do
      @p = Xi::Pattern.new([1, 2], delta: 2)
    end

    it 'returns the first +n+ events, starting from +cycle+' do
      assert_equal [[1, 0, 2, 0],
                    [2, 2, 2, 0],
                    [1, 4, 2, 1],
                    [2, 6, 2, 1]], @p.take(4)

      assert_equal [[2, 2, 2, 0],
                    [1, 4, 2, 1],
                    [2, 6, 2, 1]], @p.take(3, 1.5)
    end
  end

  describe '#take_values' do
    before do
      @p = Xi::Pattern.new([1, 2], delta: 2)
    end

    it 'returns the first +n+ events, starting from +cycle+' do
      assert_equal [1, 2, 1, 2], @p.take_values(4)
      assert_equal [2, 1, 2, 1], @p.take_values(4, 1.5)
    end
  end

  describe '#first' do
    before do
      @p = Xi::Pattern.new([1, 2], delta: 2)
    end

    it 'returns first event if +n+ is nil' do
      assert_equal [1, 0, 2, 0], @p.first
    end

    it 'returns first +n+ events, like #take' do
      assert_equal @p.take(6), @p.first(6)
    end
  end

  describe '#iteration_size' do
    describe 'when pattern is infinite' do
      before do
        @p = Xi::Pattern.new(1..inf)
      end

      it 'returns the size of delta' do
        assert_equal 1, @p.iteration_size
        assert_equal 3, @p.p(1, 2, 3).iteration_size
        assert_equal 4, @p.p([1, 2].p + [3, 4].p).iteration_size
      end
    end

    describe 'when pattern is finite' do
      before do
        @p = Xi::Pattern.new([1, 2])
      end

      it 'returns the LCM between pattern size and delta size' do
        assert_equal 2, @p.iteration_size
        assert_equal 6, @p.p(1, 2, 3).iteration_size
        assert_equal 10, @p.p([1, 2].p + [3, 4, 5].p).iteration_size
      end
    end
  end

  describe '#duration' do
    before do
      @p = Xi::Pattern.new([1, 2])
    end

    it 'returns the sum of delta values of each pattern value in a single iteration' do
      assert_equal 2, @p.duration
      assert_equal 12, @p.p(1, 2, 3).duration
      assert_equal 30, @p.p([1, 2].p + [3, 4, 5].p).duration
    end
  end
end
