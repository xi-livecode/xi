module Xi
  class Event
    attr_reader :value, :start, :duration

    def initialize(value, start=0, duration=1)
      @value = value
      @start = start
      @duration = duration
    end

    def self.[](*args)
      new(*args)
    end

    def ==(o)
      value == o.value &&
        start == o.start &&
        duration == o.duration
    end

    def end
      @start + @duration
    end

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
