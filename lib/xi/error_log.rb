require 'singleton'
require 'thread'

module Xi
  class ErrorLog
    include Singleton

    attr_accessor :max_msgs
    attr_reader   :more_errors
    alias_method  :more_errors?, :more_errors

    def initialize(max_msgs: 6)
      @max_msgs = max_msgs

      @mutex = Mutex.new
      @errors = []
      @more_errors = false
    end

    def <<(msg)
      @mutex.synchronize do
        @errors.unshift(msg) unless @errors.include?(msg)
        if @errors.size >= @max_msgs
          @errors.slice!(@max_msgs)
          @more_errors = true
        end
      end
    end

    def each
      return enum_for(:each) unless block_given?

      msgs = @mutex.synchronize do
        res = @errors.dup
        @errors.clear
        @more_errors = false
        res
      end

      while !msgs.empty?
        yield msgs.shift
      end
    end
  end
end
