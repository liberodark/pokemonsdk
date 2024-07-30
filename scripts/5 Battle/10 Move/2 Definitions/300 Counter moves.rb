module Battle
  class Move
    # Base class for counter moves, deals damage equal to 1.5/2x opponent's move.
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

    # Class managing Counter move
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

    # Class managing Mirror Coat move
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

    # Class managing Metal Burst / Comeuppance moves
    class MetalBurst < CounterBase
      private

      # Test if the attack fails
      # @param attacker [PFM::PokemonBattler] the last attacker
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean] does the attack fails ?
      def counter_fails?(attacker, user, targets)
        return counter_fails_common?(attacker, user)
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
