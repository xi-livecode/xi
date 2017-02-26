require 'test_helper'

describe Xi::Bjorklund do
  def e(*args)
    Xi::Bjorklund.new(*args)
  end

  it "e(3,5)" do
    assert_equal "x.x.x", e(3,5).to_s
  end

  it "e(4,7)" do
    assert_equal 'x.x.x.x', e(4,7).to_s
  end

  it "e(5,7)" do
    assert_equal 'x.xx.xx', e(5,7).to_s
  end

  it "e(2,8)" do
    assert_equal 'x...x...', e(2,8).to_s
  end

  it "e(3,8)" do
    assert_equal 'x..x..x.', e(3,8).to_s
  end

  it "e(4,8)" do
    assert_equal 'x.x.x.x.', e(4,8).to_s
  end

  it "e(5,8)" do
    assert_equal 'x.xx.xx.', e(5,8).to_s
  end

  it "e(7,8)" do
    assert_equal 'x.xxxxxx', e(7,8).to_s
  end

  it "e(5,9)" do
    assert_equal 'x.x.x.x.x', e(5,9).to_s
  end

  it "e(5,12)" do
    assert_equal 'x..x.x..x.x.', e(5,12).to_s
  end

  it "e(5,16)" do
    assert_equal 'x..x..x..x..x...', e(5,16).to_s
  end

  it "e(7,16)" do
    assert_equal 'x..x.x.x..x.x.x.', e(7,16).to_s
  end

  it "e(9,16)" do
    assert_equal 'x.xx.x.x.xx.x.x.', e(9,16).to_s
  end

  it "e(10,16)" do
    assert_equal 'x.xx.x.xx.xx.x.x', e(10,16).to_s
  end
end
