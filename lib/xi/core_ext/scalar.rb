require 'xi/pattern'

module Xi::CoreExt
  module Scalar
    def p(*delta, **metadata)
      [self].p(*delta, **metadata)
    end
  end
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4')
  class Fixnum; include Xi::CoreExt::Scalar; end
else
  class Integer; include Xi::CoreExt::Scalar; end
end

class Float;    include Xi::CoreExt::Scalar; end
class String;   include Xi::CoreExt::Scalar; end
class Symbol;   include Xi::CoreExt::Scalar; end
class Rational; include Xi::CoreExt::Scalar; end
class Hash;     include Xi::CoreExt::Scalar; end
