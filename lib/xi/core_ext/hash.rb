require 'xi/pattern'

module Xi
  module Pattern::Hash
    def ~
      self
    end
  end
end

class Hash
  include Xi::Pattern::Hash
end
