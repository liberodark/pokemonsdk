module Battle
  class Move
    class Endeavor < BasicWithSuccessfulEffect
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.all? { |target| user.hp >= target.hp }
          show_usage_failure(user)
          return false
        end
        return true
      end

      private

      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.hp > user.hp

          hp = target.hp - user.hp
          @scene.visual.show_hp_animations([target], [-hp])
        end
      end
    end
    Move.register(:s_endeavor, Endeavor)
  end
end
