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
      assert_equal [1, [10, 20], :foo], @p.to_a
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

  describe '.[]' do
    it 'constructs a new Pattern, same as .new' do
      assert_equal Xi::Pattern[1,2,3],
                   Xi::Pattern.new([1,2,3])

      assert_equal Xi::Pattern[1,2,3, dur: 1/2],
                   Xi::Pattern.new([1,2,3], dur: 1/2)

      assert_equal Xi::Pattern[1,2,3, dur: 1/2, gate: :note],
                   Xi::Pattern.new([1,2,3], dur: 1/2, gate: :note)
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
    before do
      @p = Xi::Pattern.new(1..4)
    end

    it 'returns an Enumerator that returns only values from the events' do
      assert_instance_of Enumerator, @p.each
      assert_equal [1, 2, 3, 4], @p.each.to_a
    end
  end

  describe '#each_event' do
    describe 'when source values are of other types' do
      it 'enumerates events from its source' do
        @p = Xi::Pattern.new([1, 2, 3])

        assert_equal [E[1,0,1], E[2,1,1], E[3,2,1]], @p.each_event.to_a
      end

      it 'enumerates events using event_duration as duration and offset' do
        @p = Xi::Pattern.new([1, 2], event_duration: 1/2)
        assert_equal [E[1,0,1/2], E[2,1/2,1/2]], @p.each_event.to_a

        @p = Xi::Pattern.new([1, 2], event_duration: 1/4)
        assert_equal [E[1,0,1/4], E[2,1/4,1/4]], @p.each_event.to_a
      end
    end

    describe 'when source values are Patterns' do
      it 'embeds patterns by taking only its values, ignoring start and duration' do
        @p = Xi::Pattern.new([1, 2, Xi::Pattern.new([10, 20]), 3])

        assert_equal [E[1,0,1], E[2,1,1], E[10,2,1], E[20,3,1], E[3,4,1]],
          @p.each_event.to_a
      end
    end

    describe 'when source values are Events' do
      it 'enumerates the same events, preserving its attributes' do
        orig_p = Xi::Pattern.new([:a, :b, :c])
          .map_events { |e| Xi::Event.new(e.value, e.start, e.duration * 0.5) }

        assert_equal orig_p.each_event.to_a, orig_p.p.each_event.to_a
      end
    end

    describe 'with no block' do
      it 'returns an Enumerator' do
        assert_instance_of Enumerator, [].p.each_event
      end
    end

    it 'preserves source' do
      @p = [1, 2, 3].p
      assert_equal @p.to_a, @p.to_a
    end
  end

  describe '#map_events' do
    before do
      @p = Xi::Pattern.new([:a, :b])
    end

    it 'returns a new Pattern with events mapped to the block' do
      new_p = @p.map_events { |e| E[e.value, e.start * 2, e.duration / 2] }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [E[:a,0,1/2], E[:b,2,1/2]], new_p.to_events
    end

    it 'is an alias of #collect' do
      assert_equal [E[:a,0,1/2], E[:b,2,1/2]],
        @p.collect_events { |e| E[e.value, e.start * 2, e.duration / 2] }.to_events
    end
  end

  describe '#select_events' do
    before do
      @p = Xi::Pattern.new(1..4)
    end

    it 'returns a new Pattern with events sellected from the block' do
      new_p = @p.select_events { |e| e.value % 2 == 0 }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [E[2,1], E[4,3]], new_p.to_events
    end

    it 'is an alias of #find_all' do
      assert_equal [E[2,1], E[4,3]],
        @p.find_all_events { |e| e.value % 2 == 0 }.to_events
    end
  end

  describe '#reject_events' do
    before do
      @p = Xi::Pattern.new(1..4)
    end

    it 'returns a new Pattern with events rejected from the block' do
      new_p = @p.reject_events { |e| e.value % 2 == 0 }

      assert_instance_of Xi::Pattern, new_p
      assert_equal [E[1,0], E[3,2]], new_p.to_events
    end
  end
end
