require 'xi/pattern/transforms'
require 'xi/pattern/generators'

module Xi
  # A Pattern is a lazy, infinite enumeration of values in time.
  #
  # An event represents a value that occurs in a specific moment in time.  It
  # is a value together with its onset (start position) in terms of cycles, and
  # its duration.  It is usually represented by a tuple of (value, start,
  # duration, iteration).  This tuple indicates when a value occurs in time
  # (start), its duration, and on which iteration of the pattern happens.
  #
  # P is an alias of Pattern, so you can build them using P instead.  Note that
  # if the pattern was built from an array, the string representation can be
  # used to build the same pattern again (almost the same ignoring whitespace
  # between constructor arguments).
  #
  #   P[1,2,3]   #=> P[1, 2, 3]
  #
  class Pattern
    extend  Generators
    include Transforms

    # Array or Proc that produces values or events
    attr_reader :source

    # Event delta in terms of cycles (default: 1)
    attr_reader :delta

    # Hash that contains metadata related to pattern usage
    attr_reader :metadata

    # Size of pattern
    attr_reader :size

    # Duration of pattern
    attr_reader :duration

    # Creates a new Pattern given either a +source+ or a +block+ that yields
    # events.
    #
    # If a block is given, +yielder+ parameter must yield +value+ and +start+
    # (optional) for each event.
    #
    # @example Pattern from an Array
    #   Pattern.new(['a', 'b', 'c']).take(5)
    #   # => [['a', 0, 1, 0],
    #   #     ['b', 1, 1, 0],
    #   #     ['c', 2, 1, 0],
    #   #     ['a', 3, 1, 1],    # starts cycling...
    #   #     ['b', 4, 1, 1]]
    #
    # @example Pattern from a block that yields only values.
    #   Pattern.new { |y| y << rand(100) }.take(5)
    #   # => [[52, 0, 1, 0],
    #   #     [8,  1, 1, 0],
    #   #     [83, 2, 1, 0],
    #   #     [25, 3, 1, 0],
    #   #     [3,  4, 1, 0]]
    #
    # @param source [Array]
    # @param size [Integer] number of events per iteration
    # @param delta [Numeric, Array<Numeric>, Pattern<Numeric>] event delta
    # @param metadata [Hash]
    # @yield [yielder, delta] yielder and event delta
    # @yieldreturn [value, start, duration]
    # @return [Pattern]
    #
    def initialize(source=nil, size: nil, delta: nil, **metadata, &block)
      if source.nil? && block.nil?
        fail ArgumentError, 'must provide source or block'
      end

      if delta && delta.respond_to?(:size) && !(delta.size < Float::INFINITY)
        fail ArgumentError, 'delta cannot be infinite'
      end

      # If delta is an array of 1 or 0 values, flatten array
      delta = delta.first if delta.is_a?(Array) && delta.size <= 1

      # Block takes precedence as source, even though +source+ can be used to
      # infer attributes
      @source = block || source

      # Infer attributes from +source+ if it is a pattern
      if source.is_a?(Pattern)
        @delta = source.delta
        @size = source.size
        @metadata = source.metadata
      else
        @delta = 1
        @size = (source.respond_to?(:size) ? source.size : nil) ||
          Float::INFINITY
        @metadata = {}
      end

      # Flatten source if it is a pattern
      @source = @source.source if @source.is_a?(Pattern)

      # Override or merge custom attributes if they were specified
      @size = size if size
      @delta = delta if delta
      @metadata.merge!(metadata)

      # Flatten delta values to an array, if it is an enumerable or pattern
      @delta = @delta.to_a if @delta.respond_to?(:to_a)

      # Set duration based on delta values
      @duration = delta_values.reduce(:+) || 0
    end

    # Create a new Pattern given an array of +args+
    #
    # @see Pattern#initialize
    #
    # @param args [Array]
    # @param kwargs [Hash]
    # @return [Pattern]
    #
    def self.[](*args, **kwargs)
      new(args, **kwargs)
    end

    # Returns a new Pattern with the same +source+, but with +delta+ overriden
    # and +metadata+ merged.
    #
    # @param delta [Array<Numeric>, Pattern<Numeric>, Numeric]
    # @param metadata [Hash]
    # @return [Pattern]
    #
    def p(*delta, **metadata)
      delta = delta.compact.empty? ? @delta : delta
      Pattern.new(@source, delta: delta, size: @size, **@metadata.merge(metadata))
    end

    # Returns true if pattern is infinite
    #
    # A Pattern is infinite if it was created from a Proc or another infinite
    # pattern, and size was not specified.
    #
    # @return [Boolean]
    # @see #finite?
    #
    def infinite?
      @size == Float::INFINITY
    end

    # Returns true if pattern is finite
    #
    # A pattern is finite if it has a finite size.
    #
    # @return [Boolean]
    # @see #infinite?
    #
    def finite?
      !infinite?
    end

    # Calls the given block once for each event, passing its value, start
    # position, duration and iteration as parameters.
    #
    # +cycle+ can be any number, even if there is no event that starts exactly
    # at that moment.  It will start from the next event.
    #
    # If no block is given, an enumerator is returned instead.
    #
    # Enumeration loops forever, and starts yielding events based on pattern's
    # delta and from the +cycle+ position, which is by default 0.
    #
    # @example block yields value, start, duration and iteration
    #   Pattern.new([1, 2], delta: 0.25).each_event.take(4)
    #   # => [[1, 0.0,  0.25, 0],
    #   #     [2, 0.25, 0.25, 0],
    #   #     [1, 0.5,  0.25, 1],
    #   #     [2, 0.75, 0.25, 1]]
    #
    # @example +cycle+ is used to start iterating from that moment in time
    #   Pattern.new([:a, :b, :c], delta: 1/2).each_event(42).take(4)
    #   # => [[:a, (42/1), (1/2), 28],
    #   #     [:b, (85/2), (1/2), 28],
    #   #     [:c, (43/1), (1/2), 28],
    #   #     [:a, (87/2), (1/2), 29]]
    #
    # @example +cycle+ can also be a fractional number
    #   Pattern.new([:a, :b, :c]).each_event(0.97).take(3)
    #   # => [[:b, 1, 1, 0],
    #   #     [:c, 2, 1, 0],
    #   #     [:a, 3, 1, 1]]
    #
    # @param cycle [Numeric]
    # @yield [v, s, d, i] value, start, duration and iteration
    # @return [Enumerator]
    #
    def each_event(cycle=0)
      return enum_for(__method__, cycle) unless block_given?
      EventEnumerator.new(self, cycle).each { |v, s, d, i| yield v, s, d, i }
    end

    # Calls the given block passing the delta of each value in pattern
    #
    # This method is used internally by {#each_event} to calculate when each
    # event in pattern occurs in time.  If no block is given, an Enumerator is
    # returned instead.
    #
    # @param index [Numeric]
    # @yield [d] duration
    # @return [Enumerator]
    #
    def each_delta(index=0)
      return enum_for(__method__, index) unless block_given?

      delta = @delta

      if delta.is_a?(Array)
        size = delta.size
        return if size == 0

        start = index.floor
        i = start % size
        loop do
          yield delta[i]
          i = (i + 1) % size
          start += 1
        end
      elsif delta.is_a?(Pattern)
        delta.each_event(index) { |v, _| yield v }
      else
        loop { yield delta }
      end
    end

    # Calls the given block once for each value in source
    #
    # @example
    #   Pattern.new([1, 2, 3]).each.to_a
    #   # => [1, 2, 3]
    #
    # @return [Enumerator]
    # @yield [Object] value
    #
    def each
      return enum_for(__method__) unless block_given?

      each_event { |v, _, _, i|
        break if i > 0
        yield v
      }
    end

    # Same as {#each} but in reverse order
    #
    # @example
    #   Pattern.new([1, 2, 3]).reverse_each.to_a
    #   # => [3, 2, 1]
    #
    # @return [Enumerator]
    # @yield [Object] value
    #
    def reverse_each
      return enum_for(__method__) unless block_given?
      each.to_a.reverse.each { |v| yield v }
    end

    # Returns an array of values from a single iteration of pattern
    #
    # @return [Array] values
    # @see #to_events
    #
    def to_a
      fail StandardError, 'pattern is infinite' if infinite?
      each.to_a
    end

    # Returns an array of events (i.e. a tuple [value, start, duration,
    # iteration]) from the first iteration.
    #
    # Only applies to finite patterns.
    #
    # @return [Array] events
    # @see #to_a
    #
    def to_events
      fail StandardError, 'pattern is infinite' if infinite?
      each_event.take(size)
    end

    # Returns a new Pattern with the results of running +block+ once for every
    # value in +self+
    #
    # If no block is given, an Enumerator is returned.
    #
    # @yield [v, s, d, i] value, start, duration and iteration
    # @yieldreturn [v, s, d] value, start (optional) and duration (optional)
    # @return [Pattern]
    #
    def map
      return enum_for(__method__) unless block_given?

      Pattern.new(self) do |y, d|
        each_event do |v, s, ed, i|
          y << yield(v, s, ed, i)
        end
      end
    end
    alias_method :collect, :map

    # Returns a Pattern containing all events of +self+ for which +block+ is
    # true.
    #
    # If no block is given, an Enumerator is returned.
    #
    # @see Pattern#reject
    #
    # @yield [v, s, d, i] value, start, duration and iteration
    # @yieldreturn [Boolean] whether value is selected
    # @return [Pattern]
    #
    def select
      return enum_for(__method__) unless block_given?

      Pattern.new(self) do |y, d|
        each_event do |v, s, ed, i|
          y << v if yield(v, s, ed, i)
        end
      end
    end
    alias_method :find_all, :select

    # Returns a Pattern containing all events of +self+ for which +block+
    # is false.
    #
    # If no block is given, an Enumerator is returned.
    #
    # @see Pattern#select
    #
    # @yield [v, s, d, i] value, start, duration and iteration
    # @yieldreturn [Boolean] whether event is rejected
    # @return [Pattern]
    #
    def reject
      return enum_for(__method__) unless block_given?

      select { |v, s, d, i| !yield(v, s, d, i) }
    end

    # Returns the first +n+ events from the pattern, starting from +cycle+
    #
    # @param n [Integer]
    # @param cycle [Numeric]
    # @return [Array] values
    #
    def take(n, cycle=0)
      each_event(cycle).take(n)
    end

    # Returns the first +n+ values from +self+, starting from +cycle+.
    #
    # Only values are returned, start position and duration are ignored.
    #
    # @see #take
    #
    def take_values(*args)
      take(*args).map(&:first)
    end

    # @see #take_values
    def peek(n=10, *args)
      take_values(n, *args)
    end

    # @see #take
    def peek_events(n=10, cycle=0)
      take(n, cycle)
    end

    # Returns the first element, or the first +n+ elements, of the pattern.
    #
    # If the pattern is empty, the first form returns nil, and the second form
    # returns an empty array.
    #
    # @see #take
    #
    # @param n [Integer]
    # @param args same arguments as {#take}
    # @return [Object, Array]
    #
    def first(n=nil, *args)
      res = take(n || 1, *args)
      n.nil? ? res.first : res
    end

    # Returns a string containing a human-readable representation
    #
    # When source is not a Proc, this string can be evaluated to construct the
    # same instance.
    #
    # @return [String]
    #
    def inspect
      ss = if @source.respond_to?(:join)
             @source.map(&:inspect).join(', ')
           elsif @source.is_a?(Proc)
             "?proc"
           else
             @source.inspect
           end

      ms = @metadata.reject { |_, v| v.nil? }
      ms.merge!(delta: delta) if delta != 1
      ms = ms.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')

      "P[#{ss}#{", #{ms}" unless ms.empty?}]"
    end
    alias_method :to_s, :inspect

    # Returns pattern interation size or length
    #
    # This is usually calculated from the least-common multiple between the sum
    # of delta values and the size of the pattern.  If pattern is infinite,
    # pattern size is assumed to be 1, so iteration size depends on delta
    # values.
    #
    # @return [Integer]
    #
    def iteration_size
      finite? ? delta_size.lcm(@size) : delta_size
    end

    # @private
    def ==(o)
      self.class == o.class &&
        delta == o.delta &&
        size == o.size &&
        duration == o.duration &&
        metadata == o.metadata &&
        (finite? && to_a == o.to_a)
    end

    private

    class EventEnumerator
      def initialize(pattern, cycle)
        @cycle = cycle

        @source = pattern.source
        @size = pattern.size
        @iter_size = pattern.iteration_size

        @iter = pattern.duration > 0 ? (cycle / pattern.duration).floor : 0
        @delta_enum = pattern.each_delta(@iter * @iter_size)
        @start = @iter * pattern.duration
        @prev_ev = nil
        @i = 0
      end

      def each(&block)
        return enum_for(__method__, @cycle) unless block_given?

        return if @size == 0

        if @source.respond_to?(:call)
          loop do
            yielder = ::Enumerator::Yielder.new do |value|
              each_block(value, &block)
            end
            @source.call(yielder, @delta_enum.peek)
          end
        elsif @source.respond_to?(:each_event)
          @source.each_event(@start) do |value, _|
            each_block(value, &block)
          end
        elsif @source.respond_to?(:[])
          loop do
            each_block(@source[@i % @size], &block)
          end
        else
          fail StandardError, 'invalid source'
        end
      end

      private

      def each_block(value)
        delta = @delta_enum.peek

        if @start >= @cycle
          if @prev_ev
            yield @prev_ev if @start > @cycle
            @prev_ev = nil
          end
          yield value, @start, delta, @iter
        else
          @prev_ev = [value, @start, delta, @iter]
        end

        @iter += 1 if @i + 1 == @iter_size
        @i = (@i + 1) % @iter_size
        @start += delta
        @delta_enum.next
      end
    end

    def delta_values
      each_delta.take(iteration_size)
    end

    def delta_size
      @delta.respond_to?(:each) && @delta.respond_to?(:size) ? @delta.size : 1
    end
  end
end

P = Xi::Pattern
