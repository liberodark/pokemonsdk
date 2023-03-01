module Battle
  module Effects
    class Ability
      # Defines the Innards Out ability
      class InnardsOut < Ability
        # Create a new ability effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @hp_remains = target.hp
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return unless skill && launcher != target && launcher

          @hp_remains = target.hp
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target
          return unless skill && launcher != target && launcher

          hp_remains = @hp_remains
          handler.scene.visual.show_ability(target)
          handler.scene.visual.show_hp_animations([launcher], [-hp_remains])
        end
      end
      register(:innards_out, InnardsOut)
    end
  end
end
