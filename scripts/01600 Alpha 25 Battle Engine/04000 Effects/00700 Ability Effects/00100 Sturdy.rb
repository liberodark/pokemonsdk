module Battle
  module Effects
    class Ability
      class Sturdy < Ability
        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false unless @target == target
          return false unless move&.ohko?

          move.scene.visual.show_ability(target)
          return true
        end

        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target || target == launcher
          return if target.hp > hp || target.hp != target.max_hp
          return unless skill
          return unless launcher&.can_be_lowered_or_canceled?

          @show_message = true
          return target.hp - 1
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return unless @show_message

          @show_message = false
          handler.scene.visual.show_ability(target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 514, target))
        end
      end

      register(:sturdy, Sturdy)
    end
  end
end
