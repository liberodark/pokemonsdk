module Battle
  class Move
    # Move that is used during 5 turn and get more powerfull until it gets interrupted
    class Rollout < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        # @type [Effects::ForcedNextMove::Rollout]
        rollout_effect = user.effects.get(:forced_next_move)
        if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
          mod = rollout_effect.successive_uses + 1
          mod += 1 if user.move_history.any? { |move| move.db_symbol == :defense_curl }
        else
          mod = 1
        end
        puts mod
        return power * mod
      end

      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        result = super
        unless result
          # @type [Effects::ForcedNextMove::Rollout]
          rollout_effect = user.effects.get(:forced_next_move)
          rollout_effect.successive_uses = 1 if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
        end
        return result
      end

      # Test move accuracy
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean] if the move can continue
      def proceed_move_accuracy(user, targets)
        result = super
        unless result
          # @type [Effects::ForcedNextMove::Rollout]
          rollout_effect = user.effects.get(:forced_next_move)
          rollout_effect.successive_uses = 1 if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
        end
        return result
      end

      # Method responsive testing accuracy and immunity.
      # It'll report the which pokemon evaded the move and which pokemon are immune to the move.
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Array<PFM::PokemonBattler>]
      def accuracy_immunity_test(user, targets)
        result = super
        if result.empty?
          # @type [Effects::ForcedNextMove::Rollout]
          rollout_effect = user.effects.get(:forced_next_move)
          rollout_effect.successive_uses = 1 if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
        end
        return result
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        # @type [Effects::ForcedNextMove::Rollout]
        rollout_effect = user.effects.get(:forced_next_move)
        if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
          rollout_effect.successive_uses += 1
        else
          rollout_effect&.kill
          user.effects.add(Effects::ForcedNextMove::Rollout.new(logic, user, self, actual_targets))
        end
      end
    end

    Move.register(:s_rollout, Rollout)
  end
end
