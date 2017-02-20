require 'xi/pattern'

module Xi
  module Pattern::Simple
    def p(delta=nil, **metadata)
      [self].p(delta, metadata)
    end
  end
end

class Fixnum;   include Xi::Pattern::Simple; end
class Float;    include Xi::Pattern::Simple; end
class String;   include Xi::Pattern::Simple; end
class Symbol;   include Xi::Pattern::Simple; end
class Rational; include Xi::Pattern::Simple; end
class Hash;     include Xi::Pattern::Simple; end
