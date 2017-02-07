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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:-@) ? -v : v) }
        end
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
          Pattern.new do |y|
            each_v { |v| y << v }
            object.each_v { |v| y << v }
          end
        else
          Pattern.new do |y|
            each_v { |v| y << (v.respond_to?(:+) ? v + object : v) }
          end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:-) ? v - numeric : v) }
        end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:*) ? v * numeric : v) }
        end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:/) ? v / numeric : v) }
        end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:%) ? v % numeric : v) }
        end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:**) ? v ** numeric : v) }
        end
      end
      alias_method :^, :**

      # Cycles pattern +repeats+ number of times, shifted by +offset+
      #
      # @example
      #   peek [1, 2, 3].p.seq              #=> [1, 2, 3]
      #   peek [1, 2, 3].p.seq(2)           #=> [1, 2, 3, 1, 2, 3]
      #   peek [1, 2, 3].p.seq(1, 1)        #=> [2, 3, 1]
      #   peek [1, 2, 3].p.seq(2, 2)        #=> [3, 2, 1, 3, 2, 1]
      #   peek [1, 2].p.seq(:inf, 1)        #=> [2, 1, 2, 1, 2, 1, 2, 1, 2, 1]
      #
      # @param repeats [Fixnum, Symbol] number or :inf (defaut: 1)
      # @param offset [Fixnum] (default: 0)
      # @return [Pattern]
      #
      def seq(repeats=1, offset=0)
        unless (repeats.is_a?(Fixnum) && repeats >= 0) || repeats == :inf
          fail ArgumentError, "repeats must be a non-negative Fixnum or :inf"
        end
        unless offset.is_a?(Fixnum) && offset >= 0
          fail ArgumentError, "offset must be a non-negative Fixnum"
        end

        Pattern.new do |y|
          rep = repeats

          loop do
            if rep != :inf
              rep -= 1
              break if rep < 0
            end

            c = offset
            offset_items = []

            is_empty = true
            each_v do |v|
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

      # Traverses the pattern in order and then in reverse order
      #
      # @example
      #   peek (0..3).p.bounce   #=> [0, 1, 2, 3, 3, 2, 1, 0]
      #
      # @return [Pattern]
      #
      def bounce
        Pattern.new do |y|
          each_v { |v| y << v }
          reverse_each_v { |v| y << v }
        end
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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:-) ? (v - min) / (max - min) : v) }
        end
      end

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
        Pattern.new do |y|
          each_v { |v| y << (v.respond_to?(:*) ? (max - min) * v + min : v) }
        end
      end

      # Scale from one range of values to another range of values
      #
      # @example
      #   peek [0,2,4,1,3,6].p.scale(0, 6, 0, 0x7f)
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

      # TODO Document
      def decelerate(num)
        Pattern.new do |y|
          each { |e| y << E[e.value, e.start * num, e.duration * num] }
        end
      end

      # TODO Document
      def accelerate(num)
        Pattern.new do |y|
          each { |e| y << E[e.value, e.start / num, e.duration / num] }
        end
      end

      # Based on +probability+, it yields original value or nil
      # TODO Document
      #
      def sometimes(probability=0.5)
        Pattern.new do |y|
          probability.p.each_v do |prob|
            each_v { |v| y << (rand < prob ? v : nil) }
          end
        end
      end

      # Repeats each value +times+
      # TODO Document
      #
      def repeat_each(times)
        Pattern.new do |y|
          times.p.each_v do |t|
            each_v { |v| t.times { y << v } }
          end
        end
      end
    end
  end
end
