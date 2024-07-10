module Battle
  module Effects
    class Ability
      class Sharpness < Ability
        # Get the base power multiplier of this move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Float]
        def base_power_multiplier(user, target, move)
          return 1 if user != @target

          return move.slicing_attack? ? 1.5 : 1
        end
      end
      register(:sharpness, Sharpness)
    end
  end
end
