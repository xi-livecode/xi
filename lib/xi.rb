require "xi/version"
require 'xi/core_ext'
require 'xi/pattern'
require 'xi/stream'
require 'xi/clock'
require 'xi/bjorklund'
require 'xi/step_sequencer'

def inf
  Float::INFINITY
end

module Xi
  def self.default_backend
    @default_backend
  end

  def self.default_backend=(new_name)
    @default_backend = new_name && new_name.to_sym
  end

  def self.default_clock
    @default_clock ||= Clock.new
  end

  def self.default_clock=(new_clock)
    @default_clock = new_clock
  end

  module Init
    def stop_all
      @streams.each { |_, ss| ss.each { |_, s| s.stop } }
    end
    alias_method :hush, :stop_all

    def start_all
      @streams.each { |_, ss| ss.each { |_, s| s.start } }
    end

    def peek(pattern, *args)
      pattern.peek(*args)
    end

    def peek_events(pattern, *args)
      pattern.peek_events(*args)
    end

    def e(n, m, value=nil)
      Bjorklund.new([n, m].min, [n, m].max, value)
    end

    def s(str, *values)
      StepSequencer.new(str, *values)
    end

    def method_missing(method, backend=nil, **opts)
      backend ||= Xi.default_backend
      super if backend.nil?

      if !backend.is_a?(String) && !backend.is_a?(Symbol)
        fail ArgumentError, "invalid backend '#{backend}'"
      end

      @streams ||= {}
      @streams[backend] ||= {}

      stream = @streams[backend][method] ||= begin
        require "xi/#{backend}"

        cls = Class.const_get("#{backend.to_s.camelize}::Stream")
        cls.new(method, Xi.default_clock, **opts)
      end

      # Define (or overwrite) a local variable named +method+ with the stream
      Pry.binding_for(self).local_variable_set(method, stream)

      stream
    end
  end
end

singleton_class.include Xi::Init

# Try to load Supercollider backend and set it as default if installed
begin
  require "xi/supercollider"
  Xi.default_backend = :supercollider
rescue LoadError
  Xi.default_backend = nil
end
