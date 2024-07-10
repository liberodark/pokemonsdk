module Battle
  class Visual
    module Transition
      # Wild transition of Diamant/Perle/Platine games
      class DPPWild < RSWild
        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :dpp_sprite_side
        end
      end
    end

    WILD_TRANSITIONS[4] = Transition::DPPWild
  end
end
