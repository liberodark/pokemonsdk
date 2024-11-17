module Battle
  module Effects
    class Ability
      class LiquidOoze < Ability
        # Function called before drain were applied (to potentially prevent healing)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param hp_healed [Integer] number of hp healed
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the drain cannot be applied
        def on_drain_prevention(handler, hp, hp_healed, target, launcher, skill)
          return unless @target == target
          return unless launcher && skill
          return unless handler.logic.damage_handler.damage_appliable(hp_healed, launcher)

          handler.scene.visual.show_ability(target, true)
          handler.logic.damage_handler.damage_change(hp_healed, launcher)
          handler.scene.visual.hide_ability(target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 457, launcher))

          return :prevent
        end
      end

      register(:liquid_ooze, LiquidOoze)
    end
  end
end
