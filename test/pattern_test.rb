require 'test_helper'

describe Xi::Pattern do
  describe '#new' do
    it 'accepts an enumerable as parameter' do
      @p = Xi::Pattern.new([1, 2, 3])

      assert_instance_of Xi::Pattern, @p
    end

    it 'accepts a block with a yielder var, like an enumerator' do
      @p = Xi::Pattern.new do |y|
        y << 1
        y << [10, 20]
        y << :foo
      end

      assert_instance_of Xi::Pattern, @p
      assert_equal [1, [10, 20], :foo], @p.to_v
    end

    it 'accepts event_duration, which defaults to 1' do
      @p = Xi::Pattern.new([1])
      assert_equal 1, @p.event_duration

      @p = Xi::Pattern.new([1], event_duration: 1/4)
      assert_equal 1/4, @p.event_duration
    end

    it 'accepts metadata as keyword arguments' do
      @p = Xi::Pattern.new([1], event_duration: 1/2, foo: :bar)

      assert_equal 1/2, @p.event_duration
      assert_equal({foo: :bar}, @p.metadata)
    end
  end

  describe '#p' do
    before do
      @p = Xi::Pattern.new([1])
    end

    it 'returns a new Pattern with the same source' do
      assert_equal @p.p.source.object_id, @p.source.object_id
    end

    it 'accepts event duration as first parameter' do
      assert_equal 1, @p.event_duration
      assert_equal 1/2, @p.p(1/2).event_duration
    end

    it 'accepts metadata as keyword arguments' do
      assert_equal({}, @p.metadata)
      assert_equal({foo: :bar}, @p.p(foo: :bar).metadata)
    end
  end

  describe '#each' do
    describe 'when source values are of other types' do
      it 'enumerates events from its source' do
        @p = Xi::Pattern.new([1, 2, 3])

        assert_equal [E[1,0,1], E[2,1,1], E[3,2,1]], @p.each.to_a
      end

      it 'enumerates events using event_duration as duration and offset' do
        @p = Xi::Pattern.new([1, 2], event_duration: 1/2)
        assert_equal [E[1,0,1/2], E[2,1/2,1/2]], @p.each.to_a

        @p = Xi::Pattern.new([1, 2], event_duration: 1/4)
        assert_equal [E[1,0,1/4], E[2,1/4,1/4]], @p.each.to_a
      end
    end

    describe 'when source values are Patterns' do
      it 'embeds patterns by taking only its values, ignoring start and duration' do
        @p = Xi::Pattern.new([1, 2, Xi::Pattern.new([10, 20]), 3])

        assert_equal [E[1,0,1], E[2,1,1], E[10,2,1], E[20,3,1], E[3,4,1]], @p.each.to_a
      end
    end

    describe 'when source values are Events' do
      it 'enumerates the same events, preserving its attributes' do
        orig_p = Xi::Pattern.new([:a, :b, :c])
          .map { |e| Xi::Event.new(e.value, e.start, e.duration * 0.5) }

        @p = Xi::Pattern.new(orig_p)

        assert_equal orig_p.each.to_a, @p.each.to_a
      end
    end

    describe 'with no block' do
      it 'returns an Enumerator' do
        assert_instance_of Enumerator, [].p.each
      end
    end

    it 'preserves source' do
      @p = [1, 2, 3].p
      assert_equal @p.to_a, @p.to_a
    end
  end
end
