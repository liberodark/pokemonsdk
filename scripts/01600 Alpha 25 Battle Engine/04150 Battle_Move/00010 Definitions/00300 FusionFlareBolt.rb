module Battle
  class Move
    class FusionFlare < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        n = 1
        n *= 2 if boosted_move?(user, target)

        return super * n
      end

      # Tell if the move will be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def boosted_move?(user, target)
        other_move_actions = logic.turn_actions.select do |a|
          a.is_a?(Actions::Attack) && Actions::Attack.from(a).launcher != user && Actions::Attack.from(a).move.db_symbol == fusion_move
        end
        return false if other_move_actions.empty?

        return other_move_actions.any? do |move_action|
          other = Actions::Attack.from(move_action).launcher
          next false unless user.attack_order > other.attack_order && other.last_successful_move_is?(fusion_move)

          next user.attack_order == other.attack_order.next
        end
      end

      # Get the other move triggering the damage boost
      # @return [db_symbol]
      def fusion_move
        return :fusion_bolt
      end
    end

    class FusionBolt < FusionFlare
      def fusion_move
        return :fusion_flare
      end
    end
    Move.register(:s_fusion_flare, FusionFlare)
    Move.register(:s_fusion_bolt, FusionBolt)
  end
end
