module Xi::CoreExt
  module Fixnum
    def /(o)
      super(o.to_r)
    end
  end
end

class Fixnum
  prepend Xi::CoreExt::Fixnum
end
