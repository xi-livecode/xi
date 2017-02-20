require 'xi/pattern'

module Xi
  module Pattern::Enumerable
    def p(delta=nil, **metadata)
      Pattern.new(self.to_a, delta: delta, **metadata)
    end
  end
end

class Enumerator
  include Xi::Pattern::Enumerable
end

class Range
  include Xi::Pattern::Enumerable
end
