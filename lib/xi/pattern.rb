require 'forwardable'
require 'xi/event'
require 'xi/pattern/transforms'
require 'xi/pattern/generators'

module Xi
  class Pattern
    include Enumerable
    include Transforms
    include Generators
    extend  Forwardable

    attr_reader :source, :event_duration, :metadata

    alias_method :dur, :event_duration

    def initialize(source=nil, **metadata)
      @source = if block_given?
        Enumerator.new { |y| yield y }
      elsif source
        source
      else
        fail ArgumentError, 'must provide source or block'
      end
      @event_duration = metadata.delete(:dur) || metadata.delete(:event_duration) || 1
      @metadata = metadata
    end

    def self.[](*args, **metadata)
      new(args, **metadata)
    end

    def ==(o)
      self.class == o.class &&
        source == o.source &&
        event_duration == o.event_duration &&
        metadata == o.metadata
    end

    def p(dur=nil, **metadata)
      Pattern.new(@source, dur: dur || @event_duration,
                  **@metadata.merge(metadata))
    end

    def each_event
      return enum_for(__method__) unless block_given?

      dur = @event_duration
      pos = 0

      @source.each do |value|
        if value.is_a?(Pattern)
          value.each do |v|
            yield Event.new(v, pos, dur)
            pos += dur
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

    def each
      return enum_for(__method__) unless block_given?
      each_event { |e| yield e.value }
    end

    def inspect
      ss = if @source.respond_to?(:join)
             @source.join(', ')
           elsif @source.is_a?(Enumerator)
             "?enum"
           else
             @source.inspect
           end

      ms = @metadata.reject { |_, v| v.nil? }
      ms.merge!(dur: dur) if dur != 1
      ms = ms.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')

      "P[#{ss}#{", #{ms}" unless ms.empty?}]"
    end
    alias_method :to_s, :inspect

    def map_events
      return enum_for(__method__) unless block_given?
      Pattern.new(dur: dur, **metadata) { |y| each_event { |e| y << yield(e) } }
    end
    alias_method :collect_events, :map_events

    def select_events
      return enum_for(__method__) unless block_given?
      Pattern.new { |y| each_event { |e| y << e if yield(e) } }
    end
    alias_method :find_all_events, :select_events

    def reject_events
      return enum_for(__method__) unless block_given?
      Pattern.new { |y| each_event { |e| y << e unless yield(e) } }
    end

    def to_events
      each_event.to_a
    end

    def peek(limit=10)
      values = take(limit + 1)
      puts "There are more than #{limit} values..." if values.size > limit
      values.take(limit)
    end

    def peek_events(limit=10)
      events = each_event.take(limit + 1)
      puts "There are more than #{limit} events..." if events.size > limit
      events.take(limit)
    end
  end
end

P = Xi::Pattern
