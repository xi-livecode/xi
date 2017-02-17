# String Inflectors, taken from ActiveSupport 5.0 source code
module Xi::Inflectors
  # Converts strings to UpperCamelCase.
  # If the +uppercase_first_letter+ parameter is set to false, then produces
  # lowerCamelCase.
  #
  # Also converts '/' to '::' which is useful for converting
  # paths to namespaces.
  #
  #   camelize('active_model')                # => "ActiveModel"
  #   camelize('active_model', false)         # => "activeModel"
  #   camelize('active_model/errors')         # => "ActiveModel::Errors"
  #   camelize('active_model/errors', false)  # => "activeModel::Errors"
  #
  # As a rule of thumb you can think of +camelize+ as the inverse of
  # #underscore, though there are cases where that does not hold:
  #
  #   camelize(underscore('SSLError'))        # => "SslError"
  def camelize
    string = self.sub(/^[a-z\d]*/) { |match| match.capitalize }
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!('/'.freeze, '::'.freeze)
    string
  end

  # Makes an underscored, lowercase form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  #   underscore('ActiveModel')         # => "active_model"
  #   underscore('ActiveModel::Errors') # => "active_model/errors"
  #
  # As a rule of thumb you can think of +underscore+ as the inverse of
  # #camelize, though there are cases where that does not hold:
  #
  #   camelize(underscore('SSLError'))  # => "SslError"
  def underscore
    return self unless self =~ /[A-Z-]|::/
    word = self.to_s.gsub('::'.freeze, '/'.freeze)
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
    word.tr!("-".freeze, "_".freeze)
    word.downcase!
    word
  end
end

class String
  include Xi::Inflectors
end
