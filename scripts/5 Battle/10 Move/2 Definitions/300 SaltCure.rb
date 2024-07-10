module Battle
  class Move
    # class managing Salt Cure move
    class SaltCure < Basic
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:salt_cure)

          target.effects.add(Effects::SaltCure.new(@logic, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 607, target)) # TODO: Must be replaced by gen IX text
        end
      end
    end
    Move.register(:s_salt_cure, SaltCure)
  end
end
