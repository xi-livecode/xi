module Xq
  class Stream
    attr_reader :clock

    def initialize(clock)
      @playing = false
      self.clock = clock
    end

    def set(pattern)
      @pattern = pattern
    end

    def clock=(new_clock)
      @clock.unsubscribe(self) if @clock
      new_clock.subscribe(self) if playing?
      @clock = new_clock
    end

    def playing?
      @playing
    end

    def stopped?
      !playing?
    end

    def play
      @playing = true
      @clock.subscribe(self)
      self
    end
    alias_method :start, :play

    def stop
      @playing = false
      @clock.unsubscribe(self)
      self
    end
    alias_method :pause, :play

    def inspect
      "#<#{self.class.class_name}:#{"0x%014x" % object_id} clock=#{@clock.inspect} #{playing? ? :playing : :stopped}>"
    end
  end
end
