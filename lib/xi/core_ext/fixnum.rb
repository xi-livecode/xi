module Xi::CoreExt
  module Fixnum
    def /(o)
      super(o.to_r)
    end
  end
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4')
  class Fixnum
    prepend Xi::CoreExt::Fixnum
  end
else
  class Integer
    prepend Xi::CoreExt::Fixnum
  end
end
