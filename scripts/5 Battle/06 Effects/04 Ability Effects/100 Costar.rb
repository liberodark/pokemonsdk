module Battle
  module Effects
    class Ability
      class Costar < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          
          allies = handler.logic.allies_of(with).reject { |ally| ally.battle_stage.all?(&:zero?) }
          return if allies.empty?

          ally = allies.sample
          
          ally.battle_stage.each_with_index do |stat_value, index| 
            next if stat_value.zero?

            with.set_stat_stage(index, stat_value)
          end

          handler.scene.visual.show_ability(with)
          handler.scene.visual.wait_for_animation
          handler.scene.display_message_and_wait(parse_text_with_2pokemon(19, 1053, with, ally))
        end
      end
      register(:costar, Costar)
    end
  end
end