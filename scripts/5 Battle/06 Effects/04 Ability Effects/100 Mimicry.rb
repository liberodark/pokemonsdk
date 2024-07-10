module Battle
  module Effects
    class Ability
      class Mimicry < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || @logic.field_terrain == :none

          if @logic.field_terrain_effect.psychic?
            @target.change_types(data_type(:psychic).id)
          elsif @logic.field_terrain_effect.misty?
            @target.change_types(data_type(:fairy).id)
          elsif @logic.field_terrain_effect.grassy?
            @target.change_types(data_type(:grass).id)
          elsif @logic.field_terrain_effect.electric?
            @target.change_types(data_type(:electric).id)
          end
          handler.scene.visual.show_ability(@target)
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param fterrain_type [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @param last_fterrain [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def on_post_fterrain_change(handler, fterrain_type, last_fterrain)
          case fterrain_type
          when :none
            @target.restore_types
          when :psychic_terrain
            @target.change_types(data_type(:psychic).id)
          when :misty_terrain
            @target.change_types(data_type(:fairy).id)
          when :grassy_terrain
            @target.change_types(data_type(:grass).id)
          when :electric_terrain
            @target.change_types(data_type(:electric).id)
          else
            return
          end
          handler.scene.visual.show_ability(@target)
        end
      end
      register(:mimicry, Mimicry)
    end
  end
end
