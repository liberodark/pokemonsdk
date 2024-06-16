module Battle
  class Visual
    module Transition
      # Wild transition of Diamant/Perle/Platine games
      class DPPWildExt < RSWildExt
        # The name of the shader
        # @return [Symbol]
        def shader_name
          return :dpp_sprite_side
        end
      end
    end

    WILD_TRANSITIONS[4] = Transition::DPPWildExt
  end
end

Graphics.on_start do
  Shader.register(:dpp_sprite_side, 'graphics/shaders/dpp_wild_ext_side.frag')
end