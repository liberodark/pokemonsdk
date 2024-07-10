module Battle
  module Effects
    class Ability
      class Libero < Ability
        NO_ACTIVATION_MOVES = %i[
          s_struggle s_metronome s_me_first s_assist s_mirror_move s_nature_power s_sleep_talk
        ]

        # Function called before the accuracy check of a move is done
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param targets [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_pre_accuracy_check(logic, scene, targets, launcher, skill)
          types = skill.definitive_types(launcher, targets.first)
          return if launcher != @target
          return if NO_ACTIVATION_MOVES.include?(skill.be_method)
          return if types.first == 0
          return unless !launcher.single_type? || !launcher.type?(types.first)

          scene.visual.show_ability(launcher)
          launcher.type1 = types.first
          launcher.type2 = 0
          launcher.type3 = 0
          text = parse_text_with_pokemon(19, 899, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                            '[VAR TYPE(0001)]' => data_type(types.first).name)
          scene.display_message_and_wait(text)
        end
      end
      register(:libero, Libero)
      register(:protean, Libero)
    end
  end
end
