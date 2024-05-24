module Battle
  class Move
    class SyrupBomb < BasicWithSuccessfulEffect
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          next if target.effects.has?(:syrup_bomb)

          target.effects.add(Effects::SyrupBomb.new(@logic, target, 3, user))
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 1210, target)) # TODO: Replace text id with gen IX texts
        end
      end
    end
    Move.register(:s_syrup_bomb, SyrupBomb)
  end
end
