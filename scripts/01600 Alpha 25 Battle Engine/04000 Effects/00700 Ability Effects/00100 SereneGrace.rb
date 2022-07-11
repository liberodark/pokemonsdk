module Battle
  module Effects
    class Ability
      class SereneGrace < Ability
        # Give the effect chance modifier given to the Pokémon with this effect
        # @param move [Battle::Move::Basic] the move the chance modifier will be applied to
        # @return [Float, Integer] multiplier
        def effect_chance_modifier(move)
          return 2
        end
      end
      register(:serene_grace, SereneGrace)
    end
  end
end
