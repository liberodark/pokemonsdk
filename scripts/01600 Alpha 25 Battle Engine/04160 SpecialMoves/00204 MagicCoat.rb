module Battle
  class Move
    # Move that inflict electrify to the ennemy
    class MagicCoat < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if @logic.battler_attacks_last?(user)
          usage_message(user)
          scene.display_message(parse_text(18, 74))
          return false
        end

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.effects.add(Effects::MagicCoat.new(@logic, target))
          @scene.display_message(parse_text_with_pokemon(19, 761, target))
        end
      end
    end

    Move.register(:s_magic_coat, MagicCoat)
  end
end
