require 'xq/event'

module Xq
  class Pattern
    extend  Forwardable

    def_delegators :@source, :each

    attr_reader :source

    def initialize(source, dur=nil)
      @source = reduce_source(source, dur)
    end

    def self.[](*args, dur: nil)
      new(args, dur)
    end

    def inspect
      "P#{@source}"
    end

    def p(dur=nil)
      Pattern.new(self, dur)
    end

    def map
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.map { |e| yield e })
    end

    def find_all
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.select { |e| yield e })
    end
    alias_method :select, :find_all

    def reject
      return enum_for(__method__) unless block_given?
      Pattern.new(@source.reject { |e| yield e })
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

P = Xq::Pattern
