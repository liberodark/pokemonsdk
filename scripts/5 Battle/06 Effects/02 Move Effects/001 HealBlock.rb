module Battle
  module Effects
    # Implement the Miracle Eye effect
    class HealBlock < PokemonTiedEffectBase
      # Create a new Pokemon HealBlock effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param turn_count [Integer]
      def initialize(logic, target, turn_count = 5)
        super(logic, target)
        self.counter = turn_count
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon
        return unless move.heal?

        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 893, user))
        return :prevent
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        return if user != @pokemon
        return unless move.heal?

        return proc { move.scene.display_message_and_wait(parse_text_with_pokemon(19, 893, user)) }
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :heal_block
      end
    end
  end
end
