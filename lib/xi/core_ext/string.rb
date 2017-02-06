require 'parslet'
require 'xi/tidal_pattern_parser'

module Xi
  module TidalPattern
    def t
      tree = Xi::TidalPatternParser.new.parse(self)
      #TidalPatternTransform.new.apply(tree)
    rescue Parslet::ParseFailed => failure
      puts failure.cause.ascii_tree
    end
  end
end

class String
  include Xi::TidalPattern
end
