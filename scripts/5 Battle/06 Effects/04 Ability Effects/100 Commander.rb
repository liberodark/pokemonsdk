module Battle
  module Effects
    class Ability
      class Commander < Ability
        COMMANDERS = {
          tatsugiri: {
            stats: { atk: 2, dfe: 2, ats: 2, dfs: 2, spd: 2 },
            ally: :dondozo
          }
        }
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return unless with.bank == @target.bank
          return unless COMMANDERS.include?(@target.db_symbol)
          return unless handler.logic.allies_of(@target).any? do |ally|
            ally.db_symbol == COMMANDERS[@target.db_symbol][:ally] && !ally.effects.has?(:commanded)
          end
          return if @target.effects.has?(:commanding)

          ally = handler.logic.allies_of(@target).first

          log_data("Commander has been activated between #{@target} (Commander) and #{ally} (commanded).")
          handler.scene.visual.show_ability(@target)
          @target.effects.add(Commanding.new(@logic, @target))
          ally.effects.add(Commanded.new(@logic, ally, @target))

          COMMANDERS[@target.db_symbol][:stats].each { |stat, power| handler.logic.stat_change_handler.stat_change_with_process(stat, power, ally, @target) }
        end
      end
      register(:commander, Commander)
    end
  end
end
