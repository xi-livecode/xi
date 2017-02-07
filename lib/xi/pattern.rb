require 'xi/event'
require 'xi/pattern/transforms'

module Xi
  class Pattern
    include Enumerable
    include Transforms

    attr_reader :source, :event_duration, :metadata

    def initialize(source=nil, event_duration: nil, **metadata)
      @source = if block_given?
        Enumerator.new { |y| yield y }
      elsif source
        source
      else
        fail ArgumentError, 'must provide source or block'
      end
      @event_duration = event_duration || 1
      @metadata = metadata
    end

    def p(dur=nil, **metadata)
      Pattern.new(@source, event_duration: dur, **metadata)
    end

    def each
      return enum_for(__method__) unless block_given?

      dur = @event_duration
      pos = 0
      @source.each do |value|
        if value.is_a?(Pattern)
          value.each do |v|
            yield v
            pos += v.duration
          end
        elsif value.is_a?(Event)
          yield value
          pos += value.duration
        else
          yield Event.new(value, pos, dur)
          pos += dur
        end
      end
    end
  end
end

P = Xi::Pattern
