module Battle
  class Move
    class Counter < Basic
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        attacker = last_attacker(user)
        if !attacker || attacker.type_ghost? || !attacker.move_history.last.move.physical?
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Method calculating the damages done by counter
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        @effectiveness = 1
        @critical = false
        return 1 unless (attacker = last_attacker(user))

        return (attacker.move_history.last.move.damage_dealt * 2).clamp(1, Float::INFINITY)
      end

      private

      # Method responsive testing accuracy and immunity.
      # It'll report the which pokemon evaded the move and which pokemon are immune to the move.
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Array<PFM::PokemonBattler>]
      def accuracy_immunity_test(user, targets)
        super(user, [last_attacker(user)].compact)
      end

      # Get the last pokemon that used a skill over the user
      # @param user [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler, nil]
      def last_attacker(user)
        # @type [Array<PFM::PokemonBattler>]
        foes = logic.foes_of(user).sort { |a, b| b.attack_order <=> a.attack_order } # higher = first
        attacker = foes.find { |foe| foe.move_history.last.targets.include?(user) && foe.move_history.last.turn == $game_temp.battle_turn }
        return attacker
      end
    end

    Move.register(:s_counter, Counter)
  end
end
