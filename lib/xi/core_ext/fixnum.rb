module Xi
  module CoerceToRational
    def /(o)
      super(o.to_r)
    end
  end
end

class Fixnum
  prepend Xi::CoerceToRational
end
