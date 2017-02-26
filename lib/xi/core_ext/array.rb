require 'xi/pattern'

module Xi::CoreExt
  module Array
    def p(*delta, **metadata)
      Xi::Pattern.new(self, delta: delta, **metadata)
    end
  end
end

class Array
  include Xi::CoreExt::Array
end
