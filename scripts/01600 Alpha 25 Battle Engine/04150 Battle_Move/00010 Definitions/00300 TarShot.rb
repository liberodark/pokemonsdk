module Battle
  class Move
    class TarShot < Basic

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:tar_shot)
          target.effects.add(Effects::TarShot.new(@logic, target, db_symbol))
        end
      end
    end
    Move.register(:s_tar_shot, TarShot)
  end
end
