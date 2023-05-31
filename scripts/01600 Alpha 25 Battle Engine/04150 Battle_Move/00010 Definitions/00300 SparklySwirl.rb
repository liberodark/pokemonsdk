module Battle
  class Move
    class SparklySwirl < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        targets = @logic.all_battlers.select { |p| p.bank == user.bank && p.party_id == user.party_id && p.alive? }
        return targets.any?(&:status?)
      end

      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        effect_targets = @logic.all_battlers.select { |p| p.bank == user.bank && (p.party_id == user.party_id || @logic.adjacent_allies_of(user).include?(p)) && p.alive? }
        effect_targets.each do |target|
          next unless target.status?

          @scene.logic.status_change_handler.status_change(:cure, target)
        end
      end
    end
    Move.register(:s_sparkly_swirl, SparklySwirl)
  end
end
