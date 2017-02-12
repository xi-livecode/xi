require 'test_helper'

describe Xi::Pattern::Transforms do
  describe '#-@' do
    it 'returns a new pattern with inverted numbers' do
      @p = -(1..5).p
      assert_equal [-1, -2, -3, -4, -5], @p.to_a
      assert_equal 5, @p.size
    end

    it 'preserves non-numeric values' do
      @p = -[1, 42, 'w', [4, 5], [10].p].p
      assert_equal [-1, -42, 'w', [4, 5], -10], @p.to_a
      assert_equal 5, @p.size
    end
  end

  describe '#+' do
    describe 'when RHS is another Pattern' do
      it 'returns a new pattern by concatenation' do
        @p = [10].p + [1,2,3].p
        assert_equal [10, 1, 2, 3], @p.to_a
        assert_equal 4, @p.size
      end
    end

    describe 'when RHS has #+ defined' do
      it 'performs a scalar sum' do
        @p = (1..5).p + 100
        assert_equal [101, 102, 103, 104, 105], @p.to_a
        assert_equal 5, @p.size
      end
    end
  end

  describe '#-' do
    describe 'when RHS has #- defined' do
      it 'performs a scalar substraction' do
        @p = (1..5).p - 10
        assert_equal [-9, -8, -7, -6, -5], @p.to_a
        assert_equal 5, @p.size
      end
    end
  end

  describe '#*' do
    describe 'when RHS has #* defined' do
      it 'performs a scalar product' do
        @p = [2, 4, 6].p * 3
        assert_equal [6, 12, 18], @p.to_a
        assert_equal 3, @p.size
      end
    end
  end

  describe '#/' do
    describe 'when RHS has #/ defined' do
      it 'performs a scalar floating-point division' do
        @p = [1, 2, 3].p / 2
        assert_equal [0.5, 1, 1.5], @p.to_a
        assert_equal 3, @p.size
      end
    end
  end

  describe '#%' do
    describe 'when RHS has #/ defined' do
      it 'performs a scalar floating-point division' do
        @p = (1..7).p % 2
        assert_equal [1, 0, 1, 0, 1, 0, 1], @p.to_a
        assert_equal 7, @p.size
      end
    end
  end

  describe '#**' do
    describe 'when RHS has #** defined' do
      it 'performs a scalar exponentiation' do
        @p = [2, 4, 6].p ** 3
        assert_equal [8, 64, 216], @p.to_a
        assert_equal 3, @p.size
      end
    end
  end

  describe '#^' do
    it 'is an alias of #**' do
      @p = [2, 4, 6].p ^ 3
      assert_equal [8, 64, 216], @p.to_a
      assert_equal 3, @p.size
    end
  end

  describe '#seq' do
    it 'fails if repeats or offset are not valid' do
      assert_raises(ArgumentError) { [].p.seq(-4) }
      assert_raises(ArgumentError) { [].p.seq("foo") }
      assert_raises(ArgumentError) { [].p.seq(1, :bar) }
    end

    it 'cycles sequentially :repeats times' do
      @p = [1, 2, 3].p.seq
      assert_equal [1, 2, 3], @p.to_a
      assert_equal 3, @p.size

      @p = [1, 2, 3].p.seq(2)
      assert_equal [1, 2, 3, 1, 2, 3], @p.to_a
      assert_equal 6, @p.size

      @p = [1, 2, 3].p.seq(0)
      assert_equal [], @p.to_a
      assert_equal 0, @p.size
    end

    it 'cycles forever if :repeats == inf' do
      @p = [1, 2, 3].p.seq(inf)
      assert_equal [1, 2, 3, 1, 2, 3, 1, 2, 3, 1], @p.take(10)
      assert @p.infinite?
    end

    it 'cycles the pattern with a different starting offset' do
      @p = (1..5).p.seq(1, 0)
      assert_equal [1, 2, 3, 4, 5], @p.to_a
      assert_equal 5, @p.size

      @p = (1..5).p.seq(1, 2)
      assert_equal [3, 4, 5, 1, 2], @p.to_a
      assert_equal 5, @p.size

      @p = (1..5).p.seq(1, 4)
      assert_equal [5, 1, 2, 3, 4], @p.to_a
      assert_equal 5, @p.size

      @p = (1..5).p.seq(1, 5)
      assert_equal [1, 2, 3, 4, 5], @p.to_a
      assert_equal 5, @p.size
    end
  end

  describe '#bounce' do
    it 'traverses original pattern and then in reverse order' do
      @p = (1..5).p.bounce.to_a
      assert_equal (1..5).to_a + (1..5).to_a.reverse, @p
      assert_equal 10, @p.size
    end
  end

  describe '#normalize' do
    it 'normalizes values from a custom range' do
      @p = (1..5).p.normalize(0, 100).to_a
      assert_equal [(1/100), (1/50), (3/100), (1/25), (1/20)], @p
      assert_equal 5, @p.size
    end
  end

  describe '#denormalize' do
    it 'scales back normalized values to a custom range' do
      @p = [0, 0.25, 0.50, 0.75].p.denormalize(0, 0x100).to_a
      assert_equal [0, 64.0, 128.0, 192.0], @p
      assert_equal 4, @p.size
    end
  end

  describe '#scale' do
    it 'scales values from a range to another' do
      @p = [0, 1, 2, 3].p.scale(0, 4, 0, 0x80).to_a
      assert_equal [(0/1), (32/1), (64/1), (96/1)], @p
      assert_equal 4, @p.size
    end
  end
end
