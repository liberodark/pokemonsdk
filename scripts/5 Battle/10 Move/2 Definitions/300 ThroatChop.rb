module Battle
  class Move
    class ThroatChop < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any? { |target| !target.effects.has?(:throat_chop) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:throat_chop)

          target.effects.add(Effects::ThroatChop.new(logic, target, user, turn_count, self))
        end
      end

      private

      # Return the number of turns the effect works
      # @return Integer
      def turn_count
        return 3
      end
    end
    Move.register(:s_throat_chop, ThroatChop)
  end
end
