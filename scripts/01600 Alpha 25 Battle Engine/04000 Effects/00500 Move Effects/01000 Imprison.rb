module Battle
  module Effects
    class Imprison < PokemonTiedEffectBase
      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if can_be_used?(user, move)

        move.logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 589, user, PFM::Text::MOVE[1] => move.name))
        return :prevent
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        return if can_be_used?(user, move)

        return proc { move.logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 589, user, PFM::Text::MOVE[1] => move.name)) }
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :imprison
      end

      private

      # Checks if the user can use the move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Boolean]
      def can_be_used?(user, move)
        return true if user == @pokemon
        return true unless move.logic.foes_of(@pokemon).include?(user)
        return true if @pokemon.moveset.none? { |pokemon_move| pokemon_move.db_symbol == move.db_symbol }
        return true if move.db_symbol == :struggle

        return false
      end
    end
  end
end