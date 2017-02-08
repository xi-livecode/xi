require "xi/version"
require 'xi/core_ext'
require 'xi/pattern'
require 'xi/event'
require 'xi/stream'
require 'xi/clock'

def inf
  Float::INFINITY
end

module Xi::Init
  def default_clock
    @default_clock ||= Clock.new
  end

  def peek(pattern, *args)
    pattern.peek(*args)
  end

  def peek_events(pattern, *args)
    pattern.peek_events(*args)
  end
end

self.extend Xi::Init
