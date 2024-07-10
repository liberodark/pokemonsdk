module Battle
  class Move
    class Octolock < Basic
      private

      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return failure_message if target.effects.has?(:bind)

        return super
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        actual_targets.any? { |target| !target.effects.has?(:bind) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:bind)

          target.effects.add(Effects::Octolock.new(logic, target, user, Float::INFINITY, self))
        end
      end

      # Display failure message
      # @return [Boolean] true for blocking
      def failure_message
        @logic.scene.display_message_and_wait(parse_text(18, 74))
        return true
      end
    end
    Move.register(:s_octolock, Octolock)
  end
end
