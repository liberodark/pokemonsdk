module Battle
  module Effects
    # Implement the Torment effect
    class Torment < PokemonTiedEffectBase
      UNSTOPPABLE_MOVES = %i[struggle]
      # Create a new Pokemon Torment effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
        @target = target
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        other_move_actions = @logic.turn_actions.select do |a|
          a.is_a?(Actions::Attack) && Actions::Attack.from(a).launcher == user
        end

        return unless user == @target
        return if other_move_actions.empty?
        return if other_move_actions.any? do |move_action|
          next true if move.db_symbol != move_action.move.db_symbol

          next false
        end

        return proc {
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 580, user))
        }
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :torment
      end
    end
  end
end
