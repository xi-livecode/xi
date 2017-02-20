require 'xi/pattern'

module Xi
  module Pattern::Array
    def p(delta=nil, **metadata)
      Pattern.new(self, delta: delta, **metadata)
    end
  end
end

class Array
  include Xi::Pattern::Array
end