module Battle
  class Move
    # Class describing a heal move
    class TakeHeart < Move
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          next unless target.status?

          scene.logic.status_change_handler.status_change(:cure, target)
        end
      end
    end

    Move.register(:s_take_heart, TakeHeart)
  end
end
