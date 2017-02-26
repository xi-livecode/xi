# Implementation adapted from Nebs' (MIT licensed)
# https://github.com/nebs/bjorklund-euclidean-rhythms
#
class Xi::Bjorklund
  def initialize(pulses, slots, value=nil)
    @pulses = pulses.to_i
    @slots = slots.to_i
    @value = value || 1
  end

  def p(*args, **metadata)
    ary = to_a
    ary.map { |v| v ? @value : nil }.p(1 / ary.size, **metadata)
  end

  def inspect
    "e(#{@pulses}, #{@slots}, #{@value.inspect})"
  end

  def to_s
    to_a.map { |i| i ? 'x' : '.' }.join
  end

  def to_a
    k = @pulses
    n = @slots

    return [] if n == 0 || k == 0

    bins = []
    remainders = []
    k.times { |i| bins[i] = [true] }
    (n-k).times { |i| remainders[i] = [false] }

    return bins.flatten if n == k

    loop do
      new_remainders = []
      bins.each_with_index do |bin, i|
        if remainders.empty?
          new_remainders.push bin
        else
          bin += remainders.shift
          bins[i] = bin
        end
      end

      if new_remainders.any?
        bins.pop new_remainders.count
        remainders = new_remainders
      end

      break unless remainders.size > 1
    end

    return (bins + remainders).flatten
  end
end
