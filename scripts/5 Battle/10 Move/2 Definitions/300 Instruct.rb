module Battle
  class Move
    class Instruct < Move
      # @type [Array<Symbol>]
      NO_INSTRUCT_MOVES = %i[sketch transform mimic king_s_shield struggle instruct metronome assist me_first mirror_move nature_power sleep_talk]

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? { |target| move_usable?(user, target) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          last_move = target.move_history.last.original_move
          target_bank = target.move_history.last.targets.first.bank
          target_position = target.move_history.last.targets.first.position

          logic.add_actions([Actions::Attack.new(scene, last_move, target, target_bank, target_position)])
          target.effects.add(Effects::Instruct.new(logic, target))
        end
      end

      private

      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @return [Boolean] if the procedure can continue
      def move_usable?(user, target)
        return false if target.effects.has?(&:preparing_attack?) || target.effects.has?(&:force_next_move?) || target.effects.has?(&:out_of_reach?)
        return false if target.move_history.none?

        last_move = target.move_history.last.original_move
        return false if last_move.pre_attack? || last_move.recharge? || last_move.two_turn? || last_move.multi_turn?
        return false if NO_INSTRUCT_MOVES.include?(last_move.db_symbol) || last_move.pp <= 0
        return false if target.moveset.none?(last_move)

        return true
      end
    end

    Move.register(:s_instruct, Instruct)
  end
end