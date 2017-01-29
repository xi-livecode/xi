require 'xq/pattern'

module Xq
  module Pattern::Enumerable
    def p(dur=nil, **metadata)
      Pattern.new(self, dur: dur, **metadata)
    end
  end
end

class Enumerator
  include Xq::Pattern::Enumerable
end

class Array
  include Xq::Pattern::Enumerable
end

class Range
  include Xq::Pattern::Enumerable
end
