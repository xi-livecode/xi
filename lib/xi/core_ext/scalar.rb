require 'xi/pattern'

module Xi::CoreExt
  module Scalar
    def p(*delta, **metadata)
      [self].p(*delta, **metadata)
    end
  end
end

class Integer;  include Xi::CoreExt::Scalar; end
class Float;    include Xi::CoreExt::Scalar; end
class String;   include Xi::CoreExt::Scalar; end
class Symbol;   include Xi::CoreExt::Scalar; end
class Rational; include Xi::CoreExt::Scalar; end
class Hash;     include Xi::CoreExt::Scalar; end
