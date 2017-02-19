module Xi
  class Pattern
    module Generators
      module ClassMethods
        # Create an arithmetic series pattern of +length+ values, being +start+
        # the starting value and +step+ the addition factor.
        #
        # @example
        #   peek P.series                 #=> [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        #   peek P.series(3)              #=> [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        #   peek P.series(0, 2)           #=> [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
        #   peek P.series(0, 0.25, 8)     #=> [0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
        #
        # @param start [Numeric] (default: 0)
        # @param step [Numeric] (default: 1)
        # @param length [Numeric, Symbol] number or inf (default: inf)
        # @return [Pattern]
        #
        def series(start=0, step=1, length=inf)
          Pattern.new(size: length) do |y|
            i = start
            loop_n(length) do
              y << i
              i += step
            end
          end
        end

        # Create a geometric series pattern of +length+ values, being +start+ the
        # starting value and +step+ the multiplication factor.
        #
        # @example
        #   peek P.geom                 #=> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        #   peek P.geom(3)              #=> [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        #   peek P.geom(1, 2)           #=> [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]
        #   peek P.geom(1, 1/2, 6)      #=> [1, (1/2), (1/4), (1/8), (1/16), (1/32)]
        #   peek P.geom(1, -1, 8)       #=> [1, -1, 1, -1, 1, -1, 1, -1]
        #
        # @param start [Numeric] (default: 0)
        # @param grow [Numeric] (default: 1)
        # @param length [Numeric, Symbol] number or inf (default: inf)
        # @return [Pattern]
        #
        def geom(start=0, grow=1, length=inf)
          Pattern.new(size: length) do |y|
            i = start
            loop_n(length) do
              y << i
              i *= grow
            end
          end
        end

        # Choose items from the list randomly
        #
        # @example
        #   peek [1, 2, 3].p.rand             #=> [2]
        #   peek [1, 2, 3, 4].p.rand(6)       #=> [1, 3, 2, 2, 4, 3]
        #
        # @param repeats [Fixnum, Symbol] number or inf (default: 1)
        # @return [Pattern]
        #
        def rand(list, repeats=1)
          Pattern.new(size: repeats) do |y|
            ls = list.to_a
            loop_n(repeats) { y << ls.sample }
          end
        end

        # Choose randomly, but only allow repeating the same item after yielding
        # all items from the list.
        #
        # @example
        #   peek [1, 2, 3, 4, 5].p.xrand    #=> [4]
        #   peek [1, 2, 3].p.xrand(8)       #=> [1, 3, 2, 3, 1, 2, 3, 2]
        #
        # @param repeats [Fixnum, Symbol] number or inf (default: 1)
        # @return [Pattern]
        #
        def xrand(list, repeats=1)
          Pattern.new(size: repeats) do |y|
            ls = list.to_a
            xs = nil
            loop_n(repeats) do |i|
              xs = ls.shuffle if i % ls.size == 0
              y << xs[i % ls.size]
            end
          end
        end

        # Shuffle the list in random order, and use the same random order
        # +repeats+ times
        #
        # @example
        #   peek [1, 2, 3, 4, 5].p.xrand    #=> [4]
        #   peek [1, 2, 3].p.xrand(8)       #=> [1, 3, 2, 3, 1, 2, 3, 2]
        #
        # @param repeats [Fixnum, Symbol] number or inf (default: 1)
        # @return [Pattern]
        #
        def shuf(list, repeats=1)
          Pattern.new(size: list.size * repeats) do |y|
            xs = list.to_a.shuffle
            loop_n(repeats) do |i|
              xs.each { |x| y << x }
            end
          end
        end

        # Generates values from a sinewave discretized to +quant+ events
        # for the duration of +dur+ cycles.
        #
        # Values range from -1 to 1
        #
        # @see #sin1 for the same function but constrained on 0 to 1 values
        #
        # @example
        #   P.sin(8).map { |i| i.round(2) }
        #     #=> [0.0, 0.71, 1.0, 0.71, 0.0, -0.71, -1.0, -0.71]
        #
        # @example +quant+ determines the size, +dur+ the total duration
        #   P.sin(8).size                 #=> 8
        #   P.sin(22).total_duration      #=> (1/1)
        #   P.sin(19, 2).total_duration   #=> (2/1)
        #
        # @param quant [Fixnum]
        # @param dur [Fixnum] (default: 1)
        # @return [Pattern]
        #
        def sin(quant, dur=1)
          Pattern.new(size: quant, dur: dur / quant) do |y|
            quant.times do |i|
              y << Math.sin(i / quant * 2 * Math::PI)
            end
          end
        end

        # Generates values from a sinewave discretized to +quant+ events
        # for the duration of +dur+ cycles.
        #
        # Values range from 0 to 1
        #
        # @see #sin
        #
        # @example
        #   P.sin1(8).map { |i| i.round(2) }
        #     #=> [0.5, 0.85, 1.0, 0.85, 0.5, 0.15, 0.0, 0.15]
        #
        # @param quant [Fixnum]
        # @param dur [Fixnum] (default: 1)
        # @return [Pattern]
        #
        def sin1(quant, dur=1)
          sin(quant, dur).scale(-1, 1, 0, 1)
        end

        private

        def loop_n(length)
          i = 0
          loop do
            break if length != inf && i == length
            yield i
            i += 1
          end
        end
      end

      def self.included(receiver)
        receiver.extend(ClassMethods)
      end
    end
  end
end
