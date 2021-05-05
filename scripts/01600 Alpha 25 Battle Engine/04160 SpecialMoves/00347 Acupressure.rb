module Battle
  class Move
    # Class that manage the Acupressure move
    # @see https://bulbapedia.bulbagarden.net/wiki/Acupressure_(move)
    # @see https://pokemondb.net/move/acupressure
    # @see https://www.pokepedia.fr/Acupression
    class Acupressure < Move
      private

      STAGES = [:acc, :atk, :ats, :dfe, :dfs, :eva, :spd]
      
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        @stage_id = (STAGES.select { |s| @logic.stat_change_handler.stat_increasable?(s, targets[0], user, self) }).sample(random: @logic.generic_rng)
        return !@stage_id.nil?
      end

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
      def on_move_failure(user, targets, reason)
        show_usage_failure(user)
        return super
      end

      # Function that deals the stat to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        @logic.stat_change_handler.stat_change(@stage_id, 2, actual_targets[0], user, self)
      end

    end
    Move.register(:s_acupressure, Acupressure)
  end
end