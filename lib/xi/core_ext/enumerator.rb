module Xi::CoreExt
  module Enumerator
    def next?
      peek
      true
    rescue StopIteration
      false
    end
  end
end

class Enumerator
  include Xi::CoreExt::Enumerator
end
