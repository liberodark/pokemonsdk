module Battle
  module Effects
    class Item
      class BigRoot < Item
        # Function called before drain were applied (to change the number of hp healed)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Float, Integer] multiplier
        def on_pre_drain(handler, hp, target, launcher, skill)
          return 1 unless launcher == @target
          return 1 unless skill

          return 1.3
        end
      end

      register(:big_root, BigRoot)
    end
  end
end
