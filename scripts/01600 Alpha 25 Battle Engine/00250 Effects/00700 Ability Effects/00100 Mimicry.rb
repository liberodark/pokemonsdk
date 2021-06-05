module Battle
  module Effects
    class Ability
      class Mimicry < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || $env.current_fterrain == 0

          if $env.terrain_psychic?
            @target.change_types(GameData::Types::PSYCHIC)
          elsif $env.terrain_misty?
            @target.change_types(GameData::Types::FAIRY)
          elsif $env.terrain_grassy?
            @target.change_types(GameData::Types::GRASS)
          elsif $env.terrain_electric?
            @target.change_types(GameData::Types::ELECTRIC)
          end
          handler.scene.visual.show_ability(@target)
        end

        # Function called after the weather was changed (post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @param last_weather [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def on_post_fterrain_change(handler, fterrain_type, last_fterrain)
          case fterrain_type
          when :terrainnone
            @target.restore_types
          when :psychic_terrain
            @target.change_types(GameData::Types::PSYCHIC)
          when :misty_terrain
            @target.change_types(GameData::Types::FAIRY)
          when :grassy_terrain
            @target.change_types(GameData::Types::GRASS)
          when :electric_terrain
            @target.change_types(GameData::Types::ELECTRIC)
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
