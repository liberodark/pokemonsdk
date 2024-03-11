
module Battle
  module Effects
    class Ability
      class Electromorphosis < Ability
        # Create a new Electromorphosis effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target

          @activated = true
          handler.scene.visual.show_ability(target)
          #TODO: Add the corresponding text
        end
        alias on_post_damage_death on_post_damage

        # Give the move base power mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def base_power_multiplier(user, target, move)
          return super unless @activated
          return super unless move.type_electric?

          @activated = false
          return 1.5
        end
      end
      register(:electromorphosis, Electromorphosis)
    end
  end
end
