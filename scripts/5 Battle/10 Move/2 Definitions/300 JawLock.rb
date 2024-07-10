module Battle
  class Move
    # Jaw Lock move
    class JawLock < Basic
      private

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return true unless user.effects.has?(:cantswitch) || actual_targets.any? { |target| target.effects.has?(:cantswitch) }

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        unless user.effects.has?(:cantswitch)
          user.effects.add(Effects::CantSwitch.new(logic, user, user, self))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 875, user))
        end

        actual_targets.each do |target|
          next if target.effects.has?(:cantswitch)

          target.effects.add(Effects::CantSwitch.new(logic, target, user, self))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 875, target))
        end
      end
    end

    Move.register(:s_jaw_lock, JawLock)
  end
end
