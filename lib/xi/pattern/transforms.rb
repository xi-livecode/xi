module Xi
  class Pattern
    module Transforms
      # Negates every number in the pattern
      #
      # Non-numeric values are ignored.
      #
      # @example
      #   peek -[10, 20, 30].p    #=> [-10, -20, -30]
      #   peek -[1, -2, 3].p      #=> [-1, 2, -3]
      #
      # @return [Pattern]
      #
      def -@
        map { |v| v.respond_to?(:-@) ? -v : v }
      end

      # Concatenate +object+ pattern or perform a scalar sum with +object+
      #
      # If +object+ is a Pattern, concatenate the two patterns.
      # Else, for each value from pattern, sum with +object+.
      # Values that do not respond to #+ are ignored.
      #
      # @example Concatenation of patterns
      #   peek [1, 2, 3].p + [4, 5, 6].p    #=> [1, 2, 3, 4, 5, 6]
      #
      # @example Scalar sum
      #   peek [1, 2, 3].p + 60             #=> [61, 62, 63]
      #   peek [0.25, 0.5].p + 0.125        #=> [0.375, 0.625]
      #   peek [0, :foo, 2].p + 1           #=> [1, :foo, 3]
      #
      # @param object [Pattern, Numeric] pattern or numeric
      # @return [Pattern]
      #
      def +(object)
        if object.is_a?(Pattern)
          Pattern.new(self, size: size + object.size) { |y, d|
            each { |v| y << v }
            object.each { |v| y << v }
          }
        else
          map { |v| v.respond_to?(:+) ? v + object : v }
        end
      end

      # Performs a scalar substraction with +numeric+
      #
      # For each value from pattern, substract with +numeric+.
      # Values that do not respond to #- are ignored.
      #
      # @example
      #   peek [1, 2, 3].p - 10       #=> [-9, -8, -7]
      #   peek [1, :foo, 3].p - 10    #=> [-9, :foo, -7]
      #
      # @param numeric [Numeric]
      # @return [Pattern]
      #
      def -(numeric)
        map { |v| v.respond_to?(:-) ? v - numeric : v }
      end

      # Performs a scalar multiplication with +numeric+
      #
      # For each value from pattern, multiplicate with +numeric+.
      # Values that do not respond to #* are ignored.
      #
      # @example
      #   peek [1, 2, 4].p * 2      #=> [2, 4, 8]
      #   peek [1, :foo].p * 2      #=> [2, :foo]
      #
      # @param numeric [Numeric]
      # @return [Pattern]
      #
      def *(numeric)
        map { |v| v.respond_to?(:*) ? v * numeric : v }
      end

      # Performs a scalar division by +numeric+
      #
      # For each value from pattern, divide by +numeric+.
      # Values that do not respond to #/ are ignored.
      #
      # @example
      #   peek [1, 2, 4].p / 2      #=> [(1/2), (1/1), (2/1)]
      #   peek [0.5, :foo].p / 2    #=> [0.25, :foo]
      #
      # @param numeric [Numeric]
      # @return [Pattern]
      #
      def /(numeric)
        map { |v| v.respond_to?(:/) ? v / numeric : v }
      end

      # Performs a scalar modulo against +numeric+
      #
      # For each value from pattern, return modulo of value divided by +numeric+.
      # Values from pattern that do not respond to #% are ignored.
      #
      # @example
      #   peek (1..5).p % 2                     #=> [1, 0, 1, 0, 1]
      #   peek [0, 1, 2, :bar, 4, 5, 6].p % 3   #=> [0, 1, 2, :bar, l, 2, 0]
      #
      # @param numeric [Numeric]
      # @return [Pattern]
      #
      def %(numeric)
        map { |v| v.respond_to?(:%) ? v % numeric : v }
      end

      # Raises each value to the power of +numeric+, which may be negative or
      # fractional.
      #
      # Values from pattern that do not respond to #** are ignored.
      #
      # @example
      #   peek (0..5).p ** 2        #=> [0, 1, 4, 9, 16, 25]
      #   peek [1, 2, 3].p ** -2    #=> [1, (1/4), (1/9)]
      #
      # @param numeric [Numeric]
      # @return [Pattern]
      #
      def **(numeric)
        map { |v| v.respond_to?(:**) ? v ** numeric : v }
      end
      alias_method :^, :**

      # Cycles pattern +repeats+ number of times, shifted by +offset+
      #
      # @example
      #   peek [1, 2, 3].p.seq              #=> [1, 2, 3]
      #   peek [1, 2, 3].p.seq(2)           #=> [1, 2, 3, 1, 2, 3]
      #   peek [1, 2, 3].p.seq(1, 1)        #=> [2, 3, 1]
      #   peek [1, 2, 3].p.seq(2, 2)        #=> [3, 2, 1, 3, 2, 1]
      #
      # @param repeats [Integer] number (defaut: 1)
      # @param offset [Integer] (default: 0)
      # @return [Pattern]
      #
      def seq(repeats=1, offset=0)
        unless repeats.is_a?(Integer) && repeats >= 0
          fail ArgumentError, "repeats must be a non-negative Integer"
        end

        unless offset.is_a?(Integer) && offset >= 0
          fail ArgumentError, "offset must be a non-negative Integer"
        end

        Pattern.new(self, size: size * repeats) do |y|
          rep = repeats

          loop do
            if rep != inf
              rep -= 1
              break if rep < 0
            end

            c = offset
            offset_items = []

            is_empty = true
            each do |v|
              is_empty = false
              if c > 0
                offset_items << v
                c -= 1
              else
                y << v
              end
            end

            offset_items.each { |v| y << v }

            break if is_empty
          end
        end
      end

      # Traverses the pattern in order and then in reverse order, skipping
      # first and last values if +skip_extremes+ is true.
      #
      # @example
      #   peek (0..3).p.bounce   #=> [0, 1, 2, 3, 2, 1]
      #   peek 10.p.bounce       #=> [10]
      #
      # @example with skip_extremes=false
      #   peek (0..3).p.bounce(false)   #=> [0, 1, 2, 3, 3, 2, 1, 0]
      #
      # @param skip_extremes [Boolean] Skip first and last values
      #   to avoid repeated values (default: true)
      # @return [Pattern]
      #
      def bounce(skip_extremes=true)
        return self if size == 0 || size == 1

        new_size = skip_extremes ? size * 2 - 2 : size * 2
        Pattern.new(self, size: new_size) { |y|
          each { |v| y << v }
          last_i = size - 1
          reverse_each.with_index { |v, i|
            y << v unless skip_extremes && (i == 0 || i == last_i)
          }
        }
      end

      # Normalizes a pattern of values that range from +min+ to +max+ to 0..1
      #
      # Values from pattern that do not respond to #- are ignored.
      #
      # @example
      #   peek (1..5).p.normalize(0, 100)
      #     #=> [(1/100), (1/50), (3/100), (1/25), (1/20)]
      #   peek [0, 0x40, 0x80, 0xc0].p.normalize(0, 0x100)
      #     #=> [(0/1), (1/4), (1/2), (3/4)]
      #
      # @param min [Numeric]
      # @param max [Numeric]
      # @return [Pattern]
      #
      def normalize(min, max)
        map { |v| v.respond_to?(:-) ? (v - min) / (max - min) : v }
      end
      alias_method :norm, :normalize

      # Scales a pattern of normalized values (0..1) to a custom range
      # +min+..+max+
      #
      # This is inverse of {#normalize}
      # Values from pattern that do not respond to #* are ignored.
      #
      # @example
      #   peek [0.01, 0.02, 0.03, 0.04, 0.05].p.denormalize(0, 100)
      #     #=> [1.0, 2.0, 3.0, 4.0, 5.0]
      #   peek [0, 0.25, 0.50, 0.75].p.denormalize(0, 0x100)
      #     #=> [0, 64.0, 128.0, 192.0]
      #
      # @param min [Numeric]
      # @param max [Numeric]
      # @return [Pattern]
      #
      def denormalize(min, max)
        map { |v| v.respond_to?(:*) ? (max - min) * v + min : v }
      end
      alias_method :denorm, :denormalize

      # Scale from one range of values to another range of values
      #
      # @example
      #   peek [0,2,4,1,3,6].p.scale(0, 6, 0, 0x7f)
      #     #=> [(0/1), (127/3), (254/3), (127/6), (127/2), (127/1)]
      #
      # @param min_from [Numeric]
      # @param max_from [Numeric]
      # @param min_to [Numeric]
      # @param max_to [Numeric]
      # @return [Pattern]
      #
      def scale(min_from, max_from, min_to, max_to)
        normalize(min_from, max_from).denormalize(min_to, max_to)
      end

      # Slows down a pattern by stretching start and duration of events
      # +num+ times.
      #
      # It is the inverse operation of #fast
      #
      # @see #fast
      #
      # @example
      #   peek_events %w(a b c d).p([1/4, 1/8, 1/6]).slow(2)
      #     #=> [E["a",0,1/2], E["b",1/2,1/4], E["c",3/4,1/3], E["d",13/12,1/2]]
      #
      # @param num [Numeric]
      # @return [Pattern]
      #
      def slow(num)
        Pattern.new(self, delta: delta.p * num)
      end

      # Advance a pattern by shrinking start and duration of events
      # +num+ times.
      #
      # It is the inverse operation of #slow
      #
      # @see #slow
      #
      # @example
      #   peek_events %w(a b c d).p([1/2, 1/4]).fast(2)
      #     #=> [E["a",0,1/4], E["b",1/4,1/8], E["c",3/8,1/4], E["d",5/8,1/8]]
      #
      # @param num [Numeric]
      # @return [Pattern]
      #
      def fast(num)
        Pattern.new(self, delta: delta.p / num)
      end

      # Based on +probability+, it yields original value or nil
      #
      # +probability+ can also be an enumerable or a *finite* Pattern. In this
      # case, for each value in +probability+ it will enumerate original
      # pattern based on that probability value.
      #
      # @example
      #   peek (1..6).p.sometimes        #=> [1, nil, 3, nil, 5, 6]
      #   peek (1..6).p.sometimes(1/4)   #=> [nil, nil, nil, 4, nil, 6]
      #
      # @example
      #   peek (1..6).p.sometimes([0.5, 1]), 12
      #     #=> [1, 2, nil, nil, 5, 6, 1, 2, 3, 4, 5, 6]
      #
      # @param probability [Numeric, #each] (default=0.5)
      # @return [Pattern]
      #
      def sometimes(probability=0.5)
        prob_pat = probability.p

        if prob_pat.infinite?
          fail ArgumentError, 'times must be finite'
        end

        Pattern.new(self, size: size * prob_pat.size) do |y|
          prob_pat.each do |prob|
            each { |v| y << (Kernel.rand < prob ? v : nil) }
          end
        end
      end

      # Repeats each value +times+
      #
      # +times+ can also be an enumerable or a *finite* Pattern.  In this case,
      # for each value in +times+, it will yield each value of original pattern
      # repeated a number of times based on that +times+ value.
      #
      # @example
      #   peek [1, 2, 3].p.repeat_each(2)   #=> [1, 1, 2, 2, 3, 3]
      #   peek [1, 2, 3].p.repeat_each(3)   #=> [1, 1, 1, 2, 2, 2, 3, 3, 3]
      #
      # @example
      #   peek [1, 2, 3].p.repeat_each([3,2]), 15
      #     #=> [1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 1, 2, 2, 3, 3]
      #
      # @param times [Numeric, #each]
      # @return [Pattern]
      #
      def repeat_each(times)
        times_pat = times.p

        if times_pat.infinite?
          fail ArgumentError, 'times must be finite'
        end

        Pattern.new(self, size: size * times_pat.size) do |y|
          times_pat.each do |t|
            each { |v| t.times { y << v } }
          end
        end
      end

      # Choose items from the list randomly, +repeats+ number of times
      #
      # @see Pattern::Generators::ClassMethods#rand
      #
      # @example
      #   peek [1, 2, 3].p.rand             #=> [2]
      #   peek [1, 2, 3, 4].p.rand(6)       #=> [1, 3, 2, 2, 4, 3]
      #
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def rand(repeats=1)
        P.rand(self, repeats)
      end

      # Choose randomly, but only allow repeating the same item after yielding
      # all items from the list.
      #
      # @see Pattern::Generators::ClassMethods#xrand
      #
      # @example
      #   peek [1, 2, 3, 4, 5].p.xrand    #=> [4]
      #   peek [1, 2, 3].p.xrand(8)       #=> [1, 3, 2, 3, 1, 2, 3, 2]
      #
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def xrand(repeats=1)
        P.xrand(self, repeats)
      end

      # Shuffle the list in random order, and use the same random order
      # +repeats+ times
      #
      # @see Pattern::Generators::ClassMethods#shuf
      #
      # @example
      #   peek [1, 2, 3, 4, 5].p.xrand    #=> [4]
      #   peek [1, 2, 3].p.xrand(8)       #=> [1, 3, 2, 3, 1, 2, 3, 2]
      #
      # @param repeats [Integer, Symbol] number or inf (default: 1)
      # @return [Pattern]
      #
      def shuf(repeats=1)
        P.shuf(self, repeats)
      end

      # Returns a new Pattern where values for which +test_proc+ are true are
      # yielded as a pattern to another +block+
      #
      # If no block is given, an Enumerator is returned.
      #
      # These values are grouped together as a "subpattern", then yielded to
      # +block+ for further transformation and finally spliced into the original
      # pattern.  +test_proc+ will be called with +value+, +start+ and +duration+
      # as parameters.
      #
      # @param test_proc [#call]
      # @yield [Pattern] subpattern
      # @yieldreturn [Pattern] transformed subpattern
      # @return [Pattern, Enumerator]
      #
      def when(test_proc, &block)
        return enum_for(__method__, test_proc) if block.nil?

        Pattern.new(self) do |y|
          each_event do |v, s, d, i|
            if test_proc.call(v, s, d, i)
              new_pat = block.call(self)
              new_pat.each_event(s)
                .take_while { |_, s_, d_| s_ + d_ <= s + d }
                .each { |v_, _| y << v_ }
            else
              y << v
            end
          end
        end
      end

      # Splices a new pattern returned from +block+ every +n+ cycles
      #
      # @see #every_iter
      #
      # @param n [Numeric]
      # @yield [Pattern] subpattern
      # @yieldreturn [Pattern] transformed subpattern
      # @return [Pattern]
      #
      def every(n, &block)
        fn = proc { |_, s, _|
          m = (s + 1) % n
          m >= 0 && m < 1
        }
        self.when(fn, &block)
      end

      # Splices a new pattern returned from +block+ every +n+ iterations
      #
      # @see #every
      #
      # @param n [Numeric]
      # @yield [Pattern] subpattern
      # @yieldreturn [Pattern] transformed subpattern
      # @return [Pattern]
      #
      def every_iter(n, &block)
        fn = proc { |_, _, _, i|
          m = (i + 1) % n
          m >= 0 && m < 1
        }
        self.when(fn, &block)
      end
    end
  end
end
