module Battle
  module Effects
    class Ability
      class AsOne < Moxie
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target

          handler.scene.visual.show_ability(with)
          handler.scene.visual.wait_for_animation
          handler.scene.display_message_and_wait(parse_text_with_pokemon(59, 2062, with))
        end

        # The stat that will be boosted
        # @return [Symbol]
        def boosted_stat
          stat = :atk if @target.form == 1
          stat = :ats if @target.form == 2

          return stat
        end
      end
      register(:as_one, AsOne)
    end
  end
end
