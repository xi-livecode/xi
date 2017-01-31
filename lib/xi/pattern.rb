require 'forwardable'
require 'xi/event'

module Xi
  class Pattern
    include Enumerable
    extend  Forwardable

    def_delegators :@reduced_source, :each, :last, :[]

    attr_reader :source, :metadata

    def initialize(source, **metadata)
      @source = source
      @metadata = metadata
      @reduced_source = reduce_source(source, metadata[:dur])
    end

    def self.[](*args, **metadata)
      new(args, metadata)
    end

    def duration
      e = @reduced_source.max_by(&:start)
      e.start + e.duration
    end

    def p(dur=nil, **metadata)
      Pattern.new(@source, dur: dur, **@metadata.merge(metadata))
    end

    def map
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.map { |e| yield e }, @metadata)
    end

    def find_all
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.select { |e| yield e }, @metadata)
    end
    alias_method :select, :find_all

    def reject
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.reject { |e| yield e }, @metadata)
    end

    def take(*args)
      Pattern.new(@source.take(*args), @metadata)
    end

    def inspect
      ms = @metadata
        .reject { |_, v| v.nil? }
        .map { |k, v| "#{k}: #{v.inspect}" }.join(', ')

      "P[#{@source.inspect}#{", #{ms}" unless ms.empty?}]"
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

      source.reduce([]) do |es, value|
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
        else
          es << Event.new(value, start, dur)
        end
      end
    end
  end
end

P = Xi::Pattern
