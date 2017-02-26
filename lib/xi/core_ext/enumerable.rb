require 'xi/pattern'

module Xi::CoreExt
  module Enumerable
    def p(*delta, **metadata)
      Xi::Pattern.new(self.to_a, delta: delta, **metadata)
    end
  end
end

class Enumerator
  include Xi::CoreExt::Enumerable
end

class Range
  include Xi::CoreExt::Enumerable
end
