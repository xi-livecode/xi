$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'xi'

require 'minitest/autorun'

def assert_pattern(expected_source, pattern)
  assert_kind_of Xi::Pattern, pattern

  source = expected_source.to_a
  assert_equal source, pattern.take_values(source.size)
end
