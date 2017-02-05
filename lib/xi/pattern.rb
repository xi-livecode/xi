require 'forwardable'
require 'xi/event'

module Xi
  class Pattern
    include Enumerable
    extend  Forwardable

    def_delegators :@reduced_source, :each, :last, :[]

    attr_reader :source, :metadata, :total_duration

    def initialize(source, **metadata)
      @source = source
      @metadata = metadata
      @reduced_source, @total_duration = reduce_source(source, metadata[:dur])
      @total_duration = metadata[:total_duration] if metadata[:total_duration]
    end

    def self.[](*args, **metadata)
      new(args, metadata)
    end

    def p(dur=nil, **metadata)
      Pattern.new(@source, dur: dur, **@metadata.merge(metadata))
    end

    def inspect
      ms = @metadata
        .reject { |_, v| v.nil? }
        .map { |k, v| "#{k}: #{v.inspect}" }.join(', ')

      "P[#{@source.join(', ')}#{", #{ms}" unless ms.empty?}]"
    end

    def to_s
      inspect
    end

    def ~
      self
    end

    private

    def reduce_source(source, dur)
      source = source.source if source.is_a?(Pattern)

      unless source.respond_to?(:reduce)
        fail 'source does not respond to #reduce'
      end

      res = source.reduce([]) do |es, value|
        start = es.last ? es.last.start + es.last.duration : 0
        if value.is_a?(Pattern)
          pes = []
          value.each do |v|
            pstart = pes.last ? pes.last.start + pes.last.duration : start
            pes << Event.new(v.value, pstart, v.default_duration? ? dur : v.duration)
          end
          es += pes
        elsif value.is_a?(Event)
          es << Event.new(value.value, value.start, value.default_duration? ? dur : value.duration)
        elsif value.is_a?(Array)
          es += value.map { |v| Event.new(v, start, dur) }
        else
          es << Event.new(value, start, dur)
        end
      end

      total_duration = res.last.start + res.last.duration
      [res, total_duration]
    end
  end
end

P = Xi::Pattern
