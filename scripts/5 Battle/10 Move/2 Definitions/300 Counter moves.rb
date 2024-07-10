module Battle
  class Move
    # Base class for counter moves
    class CounterBase < Basic
      include Mechanics::Counter

      # Test if the attack fails based on common conditions
      # @param attacker [PFM::PokemonBattler] the last attacker
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean] does the attack fails ?
      def counter_fails_common?(attacker, user)
        return true unless attacker
        return true if logic.allies_of(user).include?(attacker)
        return true unless attacker.successful_move_history&.last&.turn == $game_temp.battle_turn

        return false
      end
    end

    # When hit by a Physical Attack, user strikes back with 2x power.
    class Counter < CounterBase
      private

      # Test if the attack fails
      # @param attacker [PFM::PokemonBattler] the last attacker
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean] does the attack fails ?
      def counter_fails?(attacker, user, targets)
        return true if counter_fails_common?(attacker, user)
        return true if attacker.type_ghost?
        return true unless attacker.successful_move_history&.last&.move&.physical?

        return false
      end
    end

    # When hit by a Special Attack, user strikes back with 2x power.
    class MirrorCoat < CounterBase
      private

      # Test if the attack fails
      # @param attacker [PFM::PokemonBattler] the last attacker
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean] does the attack fails ?
      def counter_fails?(attacker, user, targets)
        return true if counter_fails_common?(attacker, user)
        return true if attacker.type_dark?
        return true unless attacker.successful_move_history&.last&.move&.special?

        return false
      end
    end

    # Deals damage equal to 1.5x opponent's attack.
    class MetalBurst < CounterBase
      private

      # Test if the attack fails
      # @param attacker [PFM::PokemonBattler] the last attacker
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean] does the attack fails ?
      def counter_fails?(attacker, user, targets)
        return true if counter_fails_common?(attacker, user)
        return true unless attacker.successful_move_history&.last&.move&.status?

        return false
      end

      # Damage multiplier if the effect proc
      # @return [Integer, Float]
      def damage_multiplier
        return 1.5
      end
    end

    Move.register(:s_counter, Counter)
    Move.register(:s_mirror_coat, MirrorCoat)
    Move.register(:s_metal_burst, MetalBurst)
  end
end
