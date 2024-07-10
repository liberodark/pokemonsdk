module Battle
  class Move
    # Implements the Poltergeist move
    class Poltergeist < Basic
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.empty? || targets.all?(:dead?) || targets.first.battle_ability_db_symbol == :__undef__
          show_usage_failure(user)
          return false
        end

        return true
      end

=begin
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          # TODO: Add the "[target] is about to be attacked by its [item]!" message
        end
      end
=end
    end
    Move.register(:s_poltergeist, Poltergeist)
  end
end
