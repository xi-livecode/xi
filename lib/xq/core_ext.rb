require 'xq/pattern'
require 'xq/event'

class Fixnum
  def p(dur=nil)
    [self].p(dur)
  end
end

class String
  def p(dur=nil)
    [self].p(dur)
  end
end

class Symbol
  def p(dur=nil)
    [self].p(dur)
  end
end

class Array
  def p(dur=nil)
    Xq::Pattern.new(self, dur)
  end
end

class Hash
  def p(dur=nil)
    Xq::Pattern.new(reduce([]) { |es, (key, val)|
      kes = []
      val.p(dur).each do |v|
        start = kes.last ? kes.last.start + kes.last.duration : 0
        kes << Xq::Event.new({key => v.value}, start, v.default_duration? ? dur : v.duration)
      end
      es += kes
    })
  end
end
