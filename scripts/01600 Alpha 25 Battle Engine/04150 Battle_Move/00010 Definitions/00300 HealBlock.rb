module Battle
  class Move
    # Move that rectricts the targets from healing in certain ways for five turns
    class HealBlock < Move
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.effects.add(Effects::HealBlock.new(@logic, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 884, target))
        end
      end
    end

    Move.register(:s_heal_block, HealBlock)
  end
end
