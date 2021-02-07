module Battle
  class Move
    # Class describing a heal move
    class HealWeather < HealMove
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          if $env.normal?
            hp = target.max_hp / 2
          elsif $env.sunny?
            hp = target.max_hp * 2 / 3
          else
            hp = target.max_hp / 4
          end
          hp = hp * 3 / 2 if pulse? && user.has_ability?(:mega_launcher)
          scene.visual.show_hp_animations([target], [hp])
          scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
        end
      end
    end

    Move.register(:s_heal_weather, HealWeather)
  end
end
