module Battle
  class Move
    class MindBlown < Basic
      # Get the reason why the move is disabled
      # @param user [PFM::PokemonBattler] user of the move
      # @return [#call] Block that should be called when the move is disabled
      def disable_reason(user)
        damp_battlers = logic.all_alive_battlers.select { |battler| battler.has_ability?(:damp) }
        return super if damp_battlers.empty?

        return proc { @logic.scene.visual.show_ability(damp_battlers.first) && @logic.scene.display_message_and_wait(parse_text_with_pokemon(60, 508, user)) }
      end

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        damp_battlers = logic.all_alive_battlers.select { |battler| battler.has_ability?(:damp) }
        unless damp_battlers.empty?
          @logic.scene.visual.show_ability(damp_battlers.first)
          return show_usage_failure(user) && false
        end

        return true
      end

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
      def on_move_failure(user, targets, reason)
        return unless %i[accuracy immunity].include?(reason)

        return crash_procedure(user)
      end

      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        super ? true : crash_procedure(user) && false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        crash_procedure(user)
      end

      private

      # Define the crash procedure when the move isn't able to connect to the target
      # @param user [PFM::PokemonBattler] user of the move
      def crash_procedure(user)
        return if user.has_ability?(:wonder_guard)

        hp = user.max_hp / 2
        scene.visual.show_hp_animations([user], [-hp])
      end
    end

    Move.register(:s_mind_blown, MindBlown)
    Move.register(:s_steel_beam, MindBlown)
    Move.register(:s_chloroblast, MindBlown)
  end
end