module Xi
  class Pattern
    module Generators
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

      # Choose items from the +list+ randomly, +repeats+ number of times
      #
      # +list+ can be a *finite* enumerable or Pattern.
      #
      # @see Pattern::Transforms#rand
      #
      # @example
      #   peek P.rand([1, 2, 3])          #=> [2]
      #   peek P.rand([1, 2, 3, 4], 6)    #=> [1, 3, 2, 2, 4, 3]
      #
      # @param list [#each] list of values
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def rand(list, repeats=1)
        Pattern.new(list, size: repeats) do |y|
          ls = list.to_a
          loop_n(repeats) { y << ls.sample }
        end
      end

      # Choose randomly, but only allow repeating the same item after yielding
      # all items from the list.
      #
      # +list+ can be a *finite* enumerable or Pattern.
      #
      # @see Pattern::Transforms#xrand
      #
      # @example
      #   peek P.xrand([1, 2, 3, 4, 5])    #=> [4]
      #   peek P.xrand([1, 2, 3], 8)       #=> [1, 3, 2, 3, 1, 2, 3, 2]
      #
      # @param list [#each] list of values
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def xrand(list, repeats=1)
        Pattern.new(list, size: repeats) do |y|
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
      # +list+ can be a *finite* enumerable or Pattern.
      #
      # @see Pattern::Transforms#shuf
      #
      # @example
      #   peek P.shuf([1, 2, 3, 4, 5])    #=> [5, 3, 4, 1, 2]
      #   peek P.shuf([1, 2, 3], 3)       #=> [2, 3, 1, 2, 3, 1, 2, 3, 1]
      #
      # @param list [#each] list of values
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def shuf(list, repeats=1)
        Pattern.new(list, size: list.size * repeats) do |y|
          xs = list.to_a.shuffle
          loop_n(repeats) do |i|
            xs.each { |x| y << x }
          end
        end
      end

      # Generates values from a sinewave discretized to +quant+ events
      # for the duration of +delta+ cycles.
      #
      # Values range from 0 to 1
      #
      # @example
      #   peek P.sin(8).map { |i| i.round(2) }
      #     #=> [0.5, 0.85, 1.0, 0.85, 0.5, 0.15, 0.0, 0.15, 0.5, 0.85]
      #
      # @example +quant+ determines the size, +delta+ the total duration
      #   P.sin(8).size           #=> 8
      #   P.sin(22).duration      #=> (1/1)
      #   P.sin(19, 2).duration   #=> (2/1)
      #
      # @param quant [Integer]
      # @param delta [Integer] (default: 1)
      # @return [Pattern]
      #
      def sin(quant, delta=1)
        Pattern.new(size: quant, delta: delta / quant) do |y|
          quant.times do |i|
            y << (Math.sin(i / quant * 2 * Math::PI) + 1) / 2
          end
        end
      end

      # Generates values from a sawtooth waveform, discretized to +quant+ events
      # for the duration of +delta+ cycles
      #
      # Values range from 0 to 1
      #
      # @example
      #   peek P.saw(8)
      #     #=> [(0/1), (1/8), (1/4), (3/8), (1/2), (5/8), (3/4), (7/8), (0/1), (1/8)]
      #
      # @example +quant+ determines the size, +delta+ the total duration
      #   P.saw(8).size           #=> 8
      #   P.saw(22).duration      #=> (1/1)
      #   P.saw(19, 2).duration   #=> (2/1)
      #
      # @param quant [Integer]
      # @param delta [Integer] (default: 1)
      # @return [Pattern]
      #
      def saw(quant, delta=1)
        Pattern.new(size: quant, delta: delta / quant) do |y|
          quant.times do |i|
            y << i / quant
          end
        end
      end

      # Generates an inverse sawtooth waveform, discretized to +quant+ events
      # for the duration of +delta+ cycles
      #
      # Values range from 0 to 1
      #
      # @see P.saw
      #
      # @example
      #   peek P.isaw(8)
      #     #=> [(1/1), (7/8), (3/4), (5/8), (1/2), (3/8), (1/4), (1/8), (1/1), (7/8)]
      #
      # @param quant [Integer]
      # @param delta [Integer] (default: 1)
      # @return [Pattern]
      #
      def isaw(*args)
        -P.saw(*args) + 1
      end

      # Generates a triangle waveform, discretized to +quant+ events for the
      # duration of +delta+ cycles
      #
      # Values range from 0 to 1
      #
      # @example
      #   peek P.tri(8)
      #     #=> [(0/1), (1/4), (1/2), (3/4), (1/1), (3/4), (1/2), (1/4), (0/1), (1/4)]
      #
      # @param quant [Integer]
      # @param delta [Integer] (default: 1)
      # @return [Pattern]
      #
      def tri(quant, delta=1)
        Pattern.new(size: quant, delta: delta / quant) do |y|
          half_quant = quant / 2
          up_half = half_quant.to_f.ceil
          down_half = quant - up_half

          up_half.times do |i|
            y << i / half_quant
          end
          down_half.times do |i|
            j = down_half - i
            y << j / half_quant
          end
        end
      end

      private

      # @private
      def loop_n(length)
        i = 0
        loop do
          break if length != inf && i == length
          yield i
          i += 1
        end
      end
    end
  end
end
