module Xq
  class Event
    attr_reader :start, :duration, :value

    def initialize(value, start=0, duration=nil)
      @value = value
      @start = start
      @duration = duration
    end

    def self.[](*args)
      new(*args)
    end

    def duration
      @duration || 1
    end

    def default_duration?
      @duration.nil?
    end

    def inspect
      "E[#{@value.inspect},#{@start}#{",#{@duration}" if @duration}]"
    end

    def p(dur=nil)
      [@value].p(dur)
    end
  end
end

E = Xq::Event
