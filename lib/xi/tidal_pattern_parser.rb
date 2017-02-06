require 'parslet'
require 'xi/tidal_pattern_transform'

module Xi
  class TidalPatternParser < Parslet::Parser
    rule(:int) { match('[0-9]').repeat(1) }

    rule(:lbracket)  { str('[') >> space? }
    rule(:rbracket)  { str(']') >> space? }
    rule(:comma)     { str(',') >> space? }
    rule(:question)    { str('?').as(:question) }
    rule(:exclamation) { str('!').as(:exclamation) }
    rule(:mult) { (str('*') >> int.as(:count)).as(:mult) }
    rule(:div)  { (str('\\').as(:div) >> int.as(:count)).as(:div) }

    rule(:space) { match('\s').repeat(1) }
    rule(:space?) { space.maybe }
    rule(:modifier) { question | exclamation | mult | div }

    rule(:integer) { match('[0-9]').repeat(1).as(:integer) }
    rule(:float) { (match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1)).as(:float) }
    rule(:rational) { (match('[0-9]').repeat(1).as(:n) >> str('/') >> match('[0-9]').repeat(1).as(:d)).as(:rational) }
    rule(:string)  { match('[a-zA-Z]').repeat(1).as(:string) }
    rule(:rest) { str('~').as(:rest) }

    rule(:clist) { (expression >> (expression).repeat).as(:clist) }
    rule(:list)  { (lbracket >> clist.maybe >> (comma >> clist).repeat >> rbracket).as(:list) }

    rule(:expression) { (float | rational | integer | string | rest | list) >> modifier.repeat.as(:modifiers) >> space? }

    root(:expression)
  end
end
