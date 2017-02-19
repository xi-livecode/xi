module Xi
  # An Event is an object that represents a scalar +value+ of some type, and
  # has a +start+ position or onset, and +duration+ in time.
  #
  # Both +start+ and +duration+ are in terms of cycles.
  #
  # Usually you don't create events, they are created by a Pattern when
  # assigned to a Stream, or by some transformation methods on Pattern, so you
  # don't need to worry about them.  Most of the time, you will manually build
  # Patterns from values and let the Pattern handle when values are applied in
  # time, based on its default event duration, for example.
  #
  # You can instantiate an Event using {.[]}, like this
  #
  #   Event.new(42, 0, 2) #=> E[42,0,2]
  #   Event[:a, 1, 1/2]   #=> E[:a,1,1/2]
  #
  # E is an alias of Event, so you can build them using E instead.  Note that
  # the string representation of the object can be used to build the same event
  # again (almost the same ignoring whitespace between constructor arguments).
  #
  #   E[:a, 1, 1/4]       #=> E[:a,1,1/4]
  #
  class Event
    attr_reader :value, :start, :duration

    # Creates a new Event with +value+, with both +start+ position and
    # +duration+ in cycles 
    #
    # @param value [Object]
    # @param start [Numeric] default: 0
    # @param duration [Numeric] default: 1
    # @return [Event]
    #
    def initialize(value, start=0, duration=1)
      @value = value
      @start = start
      @duration = duration
    end

    # @see #initialize
    def self.[](*args)
      new(*args)
    end

    def ==(o)
      self.class == o.class &&
        value == o.value &&
        start == o.start &&
        duration == o.duration
    end

    # Return the end position in cycles
    # 
    # @return [Numeric]
    #
    def end
      @start + @duration
    end

    # Creates a Pattern that only yields this event
    #
    # @param dur [Numeric, #each] event duration
    # @param metadata [Hash]
    # @return [Pattern]
    #
    def p(dur=nil, **metadata)
      [self].p(dur, metadata)
    end

    def inspect
      "E[#{@value.inspect},#{@start}" \
        "#{",#{@duration}" if @duration != 1}]"
    end

    def to_s
      inspect
    end
  end
end

E = Xi::Event
