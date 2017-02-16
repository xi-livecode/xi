require "xi/version"
require 'xi/core_ext'
require 'xi/pattern'
require 'xi/event'
require 'xi/stream'
require 'xi/clock'

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

    def inf
      Float::INFINITY
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

    def method_missing(method, backend=nil, **params)
      backend ||= Xi.default_backend

      @streams ||= {}
      @streams[backend] ||= {}
      s = @streams[backend][method] ||= begin
        cls = if backend
          require "xi/#{backend}"
          Class.const_get("#{backend.to_s.capitalize}::Stream")
        else
          Stream
        end
        cls.new(method, self.clock)
      end
      s.set(s: method, **params) unless params.empty?
      s
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
