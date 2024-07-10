module Battle
  module Effects
    class Ability
      class OrichalcumPulse < Drought
        # Give the move [Spe]atk mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_atk_multiplier(user, target, move)
          return 1 if user != @target
          return 1 unless $env.sunny? || $env.hardsun?

          return move.physical? ? 1.33 : 1
        end
      end
      register(:orichalcum_pulse, OrichalcumPulse)
    end
  end
end
