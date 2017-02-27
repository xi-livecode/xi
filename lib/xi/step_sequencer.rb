class Xi::StepSequencer
  attr_reader :string, :values

  def initialize(string, *values)
    @string = string
    @values = values
  end

  def p(*args, **metadata)
    build_pattern(**metadata)
  end

  def inspect
    "s(#{@string.inspect}" \
      "#{", #{@values.map(&:inspect).join(', ')}" unless @values.empty?})"
  end

  private

  def build_pattern(**metadata)
    val_keys = values_per_key

    values_per_bar = @string.split('|').map { |bar|
      vs = bar.split(/\s*/).reject(&:empty?)
      vs.map { |k| val_keys[k] }
    }.reject(&:empty?)

    delta = values_per_bar.map { |vs| [1 / vs.size] * vs.size }.flatten

    Pattern.new(values_per_bar.flatten, delta: delta, **metadata)
  end

  def values_per_key
    keys.map.with_index { |k, i| [k, k == '.' ? nil : @values[i]] }.to_h
  end

  def keys
    @string.scan(/\w/).uniq
  end
end
