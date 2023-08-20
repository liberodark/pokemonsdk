module Battle
  module Effects
    class Ability
      class VoltAbsorb < Ability
        # Function called when we try to check if the effect changes the definitive priority of the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_prevention_target(user, target, move)
          return false if target != @target || @target.effects.has?(:heal_block)
          return false unless move && check_move_type?(move)
          return false unless user&.can_be_lowered_or_canceled?

          move.scene.visual.show_ability(target)
          move.scene.visual.wait_for_animation
          move.logic.damage_handler.heal(target, target.max_hp / factor)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, target.hp >= target.max_hp ? 896 : 387, target))

          return true
        end

        # Function that checks the type of the move
        # @param move [Battle::Move]
        # @return [Boolean]
        def check_move_type?(move)
          return move.type_electric?
        end

        # Returns the factor used for healing
        # @return [Integer]
        def factor
          return 4
        end
      end

      class WaterAbsorb < VoltAbsorb
        # Function that checks the type of the move
         # @param move [Battle::Move]
        # @return [Boolean]
        def check_move_type?(move)
          return move.type_water?
        end
      end

      class EarthEater < VoltAbsorb
        # Function that checks the type of the move
         # @param move [Battle::Move]
        # @return [Boolean]
        def check_move_type?(move)
          return move.type_ground?
        end
      end

      register(:volt_absorb, VoltAbsorb)
      register(:water_absorb, WaterAbsorb)
      register(:earth_eater, EarthEater)
    end
  end
end
