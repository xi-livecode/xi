require "xi/version"
require 'xi/core_ext'
require 'xi/pattern'
require 'xi/event'
require 'xi/stream'
require 'xi/clock'

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

  module Init
    def peek(pattern, *args)
      pattern.peek(*args)
    end

    def peek_events(pattern, *args)
      pattern.peek_events(*args)
    end

    def clock
      @default_clock ||= Clock.new
    end

    def stop_all
      @streams.each do |backend, ss|
        ss.each do |name, stream|
          stream.stop
        end
      end
    end
    alias_method :hush, :stop_all

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
        cls.new(method, self.clock, **opts)
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
