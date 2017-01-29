require "xq/version"
require 'xq/core_ext'
require 'xq/pattern'
require 'xq/event'
require 'xq/stream'
require 'xq/clock'

module Xq::Init
  def default_clock
    @default_clock ||= Clock.new
  end

  def s1
    @s1 ||= Stream.new(default_clock)
  end
end

self.extend Xq::Init
