require 'test_helper'

describe Xi::Pattern::Generators do
  describe '.series' do
    it do
      @p = P.series
      assert_equal (0..9).to_a, @p.take(10)
      assert @p.infinite?
    end

    it 'accepts a starting number' do
      @p = P.series(3)
      assert_equal [3, 4, 5, 6, 7, 8, 9, 10, 11, 12], @p.take(10)
      assert @p.infinite?
    end

    it 'accepts starting and step numbers' do
      @p = P.series(0, 2)
      assert_equal [0, 2, 4, 6, 8, 10, 12, 14, 16, 18], @p.take(10)
      assert @p.infinite?
    end

    it 'accepts starting, step and length numbers' do
      @p = P.series(0, 0.25, 8)
      assert_equal [0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75], @p.to_a
      assert @p.finite?
      assert_equal 8, @p.size
    end
  end

  describe '.geom' do
    it do
      @p = P.geom
      assert_equal [0] * 10, @p.take(10)
      assert @p.infinite?
    end

    it 'accepts a starting number' do
      @p = P.geom(3)
      assert_equal [3] * 10, @p.take(10)
      assert @p.infinite?
    end

    it 'accepts starting and step numbers' do
      @p = P.geom(1, 2)
      assert_equal [1, 2, 4, 8, 16, 32, 64, 128, 256, 512], @p.take(10)
      assert @p.infinite?
    end

    it 'accepts starting, step and length numbers' do
      @p = P.geom(1, -1, 8)
      assert_equal [1, -1, 1, -1, 1, -1, 1, -1], @p.to_a
      assert @p.finite?
      assert_equal 8, @p.size
    end
  end

  describe '.rand' do
    it do
      @p = P.rand(1..5)
      assert @p.finite?
      assert_equal 1, @p.size
      assert (1..5).include?(@p.first)

      @p = P.rand(1..5, 6)
      assert @p.finite?
      assert_equal 6, @p.size
      assert @p.all? { |v| (1..5).include?(v) }
    end
  end

  describe '.xrand' do
    it do
      @p = P.xrand(1..5)
      assert @p.finite?
      assert_equal 1, @p.size
      assert (1..5).include?(@p.first)

      @p = P.xrand(1..3, 9)
      assert @p.finite?
      assert_equal 9, @p.size
      @p.each_slice(3) do |slice|
        assert_equal (1..3).to_a, slice.sort
      end
    end
  end

  describe '.shuf' do
    it do
      @p = P.shuf(1..5)
      assert @p.finite?
      assert_equal 5, @p.size
      assert (1..5).include?(@p.first)

      @p = P.shuf(1..3, 3)
      assert @p.finite?
      assert_equal 9, @p.size
      @p.each_slice(3) do |slice|
        assert_equal (1..3).to_a, slice.sort
      end
    end
  end
end
