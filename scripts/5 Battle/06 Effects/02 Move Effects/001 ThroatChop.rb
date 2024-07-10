module Battle
  module Effects
    class ThroatChop < PokemonTiedEffectBase
      # The Pokemon that launched the attack
      # @return [PFM::PokemonBattler]
      attr_reader :origin

      # Create a new Throat Chop effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      # @param turn_count [Integer]
      # @param move [Battle::Move] move responsive of the effect
      def initialize(logic, target, origin, turn_count, move)
        super(logic, target)
        @origin = origin
        @move = move
        self.counter = turn_count
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        return if user != @pokemon
        return unless move.sound_attack?

        return proc {
          move.scene.display_message_and_wait(parse_text_with_pokemon(59, 1860, user, PFM::Text::PKNICK[1] => user.name))
        }
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon
        return unless move.sound_attack?

        move.scene.display_message_and_wait(parse_text_with_pokemon(59, 1860, user, PFM::Text::PKNICK[1] => user.name))
        return :prevent
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :throat_chop
      end
    end
  end
end