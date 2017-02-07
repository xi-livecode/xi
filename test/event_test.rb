require 'test_helper'

describe Xi::Event do
  describe '.new' do
    it 'accepts a value, an optional start an duration parameters' do
      @e = Xi::Event.new(5)
      assert_equal 5, @e.value
      assert_equal 0, @e.start
      assert_equal 1, @e.duration

      @e = Xi::Event.new(5, 1/2)
      assert_equal 5, @e.value
      assert_equal 1/2, @e.start
      assert_equal 1, @e.duration

      @e = Xi::Event.new(5, 1/2, 2)
      assert_equal 5, @e.value
      assert_equal 1/2, @e.start
      assert_equal 2, @e.duration
    end
  end

  describe '.[]' do
    it 'constructs a new Event, same as .new' do
      assert_equal Xi::Event[:a],         Xi::Event.new(:a)
      assert_equal Xi::Event[:a, 1/2],    Xi::Event.new(:a, 1/2)
      assert_equal Xi::Event[:a, 1/2, 1], Xi::Event.new(:a, 1/2, 1)
    end
  end

  describe '#end' do
    it 'returns when the event finishes' do
      @e = Xi::Event.new(:a, 1/4, 1/4)
      assert_equal 1/2, @e.end

      @e = Xi::Event.new(:b, 2, 4)
      assert_equal 6, @e.end
    end
  end

  describe '#p' do
    it 'returns a Pattern which enumerates the same Event' do
      @e = Xi::Event.new(:a, 1, 4)
      assert_equal [@e], @e.p.to_events
    end
  end

  describe '#inspect' do
    it 'returns a custom inspection string' do
      @e = Xi::Event.new(:a)
      assert_equal "E[:a,0]", @e.inspect

      @e = Xi::Event.new(:a, 4)
      assert_equal "E[:a,4]", @e.inspect

      @e = Xi::Event.new(:a, 4, 2)
      assert_equal "E[:a,4,2]", @e.inspect
    end
  end
end
