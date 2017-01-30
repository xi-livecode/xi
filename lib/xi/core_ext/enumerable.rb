require 'xi/pattern'

module Xi
  module Pattern::Enumerable
    def p(dur=nil, **metadata)
      Pattern.new(self, dur: dur, **metadata)
    end
  end
end

class Enumerator
  include Xi::Pattern::Enumerable
end

class Array
  include Xi::Pattern::Enumerable
end

class Range
  include Xi::Pattern::Enumerable
end
