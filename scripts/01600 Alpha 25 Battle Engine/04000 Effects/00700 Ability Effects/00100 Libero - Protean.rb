module Battle
  module Effects
    class Ability
      class Libero < Ability
        # Function called after the accuracy check of a move is done (and the move should land)
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param targets [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_accuracy_check(logic, scene, targets, launcher, skill)
          return if launcher != @target

          if launcher.type2 != 0
            scene.visual.show_ability(launcher)
            launcher.type1 = skill.type
            launcher.type2 = 0
            launcher.type3 = 0
            text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(skill.type).name)
            scene.display_message_and_wait(text)
          end

          unless launcher.type?(skill.type)
            scene.visual.show_ability(launcher)
            launcher.type1 = skill.type
            launcher.type2 = 0
            launcher.type3 = 0
            text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(skill.type).name)
            scene.display_message_and_wait(text)
          end
        end
      end
      register(:libero, Libero)
      register(:protean, Libero)
    end
  end
end
