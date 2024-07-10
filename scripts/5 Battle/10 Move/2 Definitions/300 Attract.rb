module Battle
  class Move
    # Move that inflict attract effect to the ennemy
    class Attract < Move
      private

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true unless user.gender * target.gender == 2
        return true if target.effects.has?(:attract)

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.effects.add(Effects::Attract.new(logic, target, user))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 327, target))

          handle_destiny_knot_effect(user, target) if target.hold_item?(:destiny_knot)
        end
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      def handle_destiny_knot_effect(user, target)
        return if user.effects.has?(:attract)

        user.effects.add(Effects::Attract.new(logic, user, target))
        scene.visual.show_item(target)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 327, user))
      end
    end

    Move.register(:s_attract, Attract)
  end
end
