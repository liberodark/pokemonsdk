module Battle
  class Move
    # Class that defines the move Sparkling Aria
    class SparklingAria < Basic
      # Function that indicates the status to check
      def status_condition
        return :burn
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.status == Configs.states.ids[status_condition]

          @logic.status_change_handler.status_change_with_process(:cure, target, user, self)
        end
      end
    end
    Move.register(:s_sparkling_aria, SparklingAria)
  end
end
