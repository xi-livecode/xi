module Xi::Enumerator
  def next?
    peek
    true
  rescue StopIteration
    false
  end
end

class Enumerator
  include Xi::Enumerator
end
