module Battle
  module Effects
    class Weather
      class Hail < Weather
        # List of abilities that blocks hail damages
        HAIL_BLOCKING_ABILITIES = %i[magic_guard ice_body snow_cloak overcoat]
        # List of objects that block hail damages
        HAIL_BLOCKING_ITEMS = %i[safety_goggles]
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          if $env.decrease_weather_duration
            scene.display_message_and_wait(parse_text(18, 95))
            logic.weather_change_handler.weather_change(:none, 0)
          else
            scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 495)
            scene.display_message_and_wait(parse_text(18, 99))
            battlers.each do |battler|
              next if battler.dead?
              next if hail_immunity?(battler)

              logic.damage_handler.damage_change((battler.max_hp / 16).clamp(1, Float::INFINITY), battler)
            end
          end
        end

        private

        # Check if we have an immunity to hail
        # @param battler [PFM::PokemonBattler]
        # @return [Boolean]
        def hail_immunity?(battler)
          return true if HAIL_BLOCKING_ABILITIES.include?(battler.battle_ability_db_symbol)
          return true if HAIL_BLOCKING_ITEMS.include?(battler.battle_item_db_symbol)
          return true if battler.type_ice?
          return true if battler.effects.has?(:out_of_reach_base)

          return false
        end
      end
      register(:hail, Hail)
    end
  end
end
