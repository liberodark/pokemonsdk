module Battle
  class Move
    # Move that deals damage and knocks the target to the ground
    class SmackDown < Basic
      private

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.none? { |target| ineffective_against_target?(target) } || !logic.terrain_effects.has?(:gravity)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if ineffective_against_target?(target)

          # TODO: Add Sky Drop exception
          target.effects.add(Effects::SmackDown.new(logic, target))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1134, target))
        end
      end

      # Test if a specific effect is ineffective against a target
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def ineffective_against_target?(target)
        return true if target.dead?
        return true if target.grounded? && !target.effects.has?(:out_of_reach_base)
        return true if target.effects.has?(:substitute) && !authentic? || target.effects.has?(:ingrain)
        return true if target.hold_item?(:iron_ball)
        
        return false
      end
    end

    Move.register(:s_smack_down, SmackDown)
  end
end
