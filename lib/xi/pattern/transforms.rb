module Xi
  class Pattern
    module Transforms
      def decelerate(num)
        Pattern.new { |y|
          each { |e| y << E[e.value, e.start * num, e.duration * num] }
        }
      end

      def accelerate(num)
        Pattern.new { |y|
          each { |e| y << E[e.value, e.start / num, e.duration / num] }
        }
      end
    end
  end
end
