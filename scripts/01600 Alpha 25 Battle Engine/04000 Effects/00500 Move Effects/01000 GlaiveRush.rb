module Battle
  module Effects
    # Implement the Glaive Rush effect
    class GlaiveRush < PokemonTiedEffectBase
      # Function called at the end of an action
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_post_action_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead?
        return if logic.actions.any? { |a| a.is_a?(Actions::Attack) && a.launcher == @pokemon }

        last_move = @pokemon.move_history&.last
        return if last_move&.db_symbol == :glaive_rush

        kill
      end

      # Give the move mod3 mutiplier (after everything)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param move [Battle::Move] move
      # @return [Float, Integer] multiplier
      def mod3_multiplier(user, target, move)
        return 2 unless target == @pokemon

        return super
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :glaive_rush
      end
    end
  end
end
