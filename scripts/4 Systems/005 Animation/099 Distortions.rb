module Yuki
  # Module containing all the animation utility
  module Animation

    module_function

    pi_div2 = Math::PI / 2

    # Causal method
    # @param x [Float, Integer]
    # @return [Float]
    def r(x)
      return 0 if x.negative?

      return x
    end

    # Hash describing all the distortion proc
    DISTORTIONS = {
      # Proc defining the SMOOTH Time distortion
      SMOOTH_DISTORTION: proc { |x| 1 - Math.cos(pi_div2 * x**1.5)**5 },
      # Proc defining the UNICITY Time distortion (no distortion at all)
      UNICITY_DISTORTION: proc { |x| x },
      # Proc defining the SQUARE 0 to 1 to 0 distortion
      SQUARE010_DISTORTION: proc { |x| 1 - (x * 2 - 1)**2 },
      SIN: proc { |x| Math.sin(2 * Math::PI * x) },
      # Falling distortion with little vibrations at the end
      FALLING_SMOOTH: proc { |x| 5 * r(x) - 6 * r(x - 0.2) + 1.25 * r(x - 0.4) - 0.25 * r(x - 0.6) }
    }
  end
end
