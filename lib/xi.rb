require "xi/version"
require 'xi/core_ext'
require 'xi/pattern'
require 'xi/event'
require 'xi/stream'
require 'xi/clock'

module Xi::Init
  def default_clock
    @default_clock ||= Clock.new
  end
end

self.extend Xi::Init
