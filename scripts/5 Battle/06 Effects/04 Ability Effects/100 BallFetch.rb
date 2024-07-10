module Battle
  module Effects
    class Ability
      class BallFetch < Ability
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless pick_up_possible?(logic)

          scene.visual.show_ability(@target)
          logic.item_change_handler.change_item($bag.last_ball_used_db_symbol, true, @target)
          @target.ability_used = true
        end

        private

        # Function that check if we can pick up Pokeball
        # @param logic [Battle::Logic] logic of the battle
        # @return [Boolean]
        def pick_up_possible?(logic)
          result = logic.ball_fetch_on_field

          return false if result.empty? || result.first != @target
          return false if @target.dead? || @target.ability_used || @target.battle_item_db_symbol != :__undef__
          return false if $bag.last_ball_used_db_symbol == :__undef__

          return true
        end
      end
      register(:ball_fetch, BallFetch)
    end
  end
end