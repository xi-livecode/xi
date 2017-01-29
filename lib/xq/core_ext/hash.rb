require 'xq/pattern'
require 'xq/event'

module Xq
  module Pattern::Hash
    def p(dur=nil, **metadata)
      Pattern.new(reduce([]) { |es, (key, val)|
        kes = []
        val.p(dur).each do |v|
          start = kes.last ? kes.last.start + kes.last.duration : 0
          kes << Event.new({key => v.value}, start, v.default_duration? ? dur : v.duration)
        end
        es += kes
      }, dur: dur, **metadata)
    end
  end
end

class Hash
  include Xq::Pattern::Hash
end
