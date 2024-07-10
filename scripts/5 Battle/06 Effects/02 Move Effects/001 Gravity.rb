module Battle
  module Effects
    class Gravity < EffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      def initialize(logic)
        super

        self.counter = 5
        logic.scene.display_message_and_wait(parse_text(18, 123))
        kill_flying_effects(logic.all_alive_battlers)
      end

      # Return the chance of hit multiplier
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param move [Battle::Move]
      # @return [Float]
      def chance_of_hit_multiplier(user, target, move)
        return super if move.ohko?

        return 5.0 / 3
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return unless move.gravity_affected?

        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 1092, user, PFM::Text::MOVE[1] => move.name))
        return :prevent
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        return unless move.gravity_affected?

        return proc {
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 1092, user, PFM::Text::MOVE[1] => move.name))
        }
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :gravity
      end

      # Show the message when the effect gets deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 124))
      end

      private

      # kill effects that force battlers to fly
      # @param battlers [Array<PFM::PokemonBattler>]
      def kill_flying_effects(battlers)
        battlers.each do |battler|
          battler.effects.get(:magnet_rise)&.kill
          battler.effects.get(:telekinesis)&.kill
          
          if %i[bounce fly].include?(battler.effects.get(:out_of_reach_base)&.move&.db_symbol)
            battler.effects.get(&:out_of_reach?)&.kill
            battler.effects.get(&:force_next_move?)&.kill
            @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 908, battler))
          end
        end
      end
    end
  end
end
