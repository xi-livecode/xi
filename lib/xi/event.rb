module Xi
  class Event
    attr_reader :start, :value

    def initialize(value, start=0, duration=nil)
      @value = value
      @start = start
      @duration = duration
    end

    def self.[](*args)
      new(*args)
    end

    def ==(o)
      [@value, @start, @duration] == [o.value, o.start, o.duration]
    end

    def end
      @start + duration
    end

    def duration
      @duration || 1
    end

    def default_duration?
      @duration.nil?
    end

    def p(dur=nil)
      [@value].p(dur)
    end

    def inspect
      "E[#{@value.inspect},#{@start}#{",#{@duration}" if @duration}]"
    end

    def to_s
      inspect
    end
  end
end

E = Xi::Event
