module Xi::CoreExt
  module Integer
    def /(o)
      super(o.to_r)
    end
  end
end

class Integer
  prepend Xi::CoreExt::Integer
end
