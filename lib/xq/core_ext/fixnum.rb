module Xq
  module CoerceToRational
    def /(o)
      super(o.to_r)
    end
  end
end

class Fixnum
  prepend Xq::CoerceToRational
end
