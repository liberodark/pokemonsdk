module Battle
  module Effects
    class Ability
      class Stakeout < Ability
        # Get the base power multiplier of this move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Float]
        def base_power_multiplier(user, target, move)
          return 1 if user != @target
          return 1 if @target.turn_count < 1

          return target.switching? ? 2 : 1
        end
      end
      register(:stakeout, Stakeout)
    end
  end
end
