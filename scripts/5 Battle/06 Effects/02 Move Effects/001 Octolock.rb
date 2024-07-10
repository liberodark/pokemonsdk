module Battle
  module Effects
    class Octolock < Bind
      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return kill if @origin.dead?
        return if @pokemon.dead?

        scene.display_message(message)
        logic.stat_change_handler.stat_change_with_process(:dfe, -1, @pokemon, @origin)
        logic.stat_change_handler.stat_change_with_process(:dfs, -1, @pokemon, @origin)
      end
    end
  end
end