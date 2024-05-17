module Battle
  class Move
    # class managing Dragon Cheer
    class DragonCheer < Move
      UNSTACKABLE_EFFECTS = %i[dragon_cheer focus_energy]

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? || targets.all? { |target| UNSTACKABLE_EFFECTS.any? { |e| target.effects.has?(e) } }

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if UNSTACKABLE_EFFECTS.any? { |e| target.effects.has?(e) }

          target.effects.add(Effects::DragonCheer.new(@logic, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 1047, target))
        end
      end
    end

    Move.register(:s_dragon_cheer, DragonCheer)
  end
end
