module Battle
  module Effects
    class Item
      class LeppaBerry < Berry
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @target.moveset.none? { |move| move.pp == 0 }

          process_effect(@target, nil, nil)
        end

        # Function that executes the effect of the berry (for Pluck & Bug Bite)
        # @param force_heal [Boolean] tell if a healing berry should force the heal
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def execute_berry_effect(force_heal: false, force_execution: false)
          process_effect(@target, nil, nil, force_execution)
        end

        private

        # Function that process the effect of the berry (if possible)
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def process_effect(target, launcher, skill, force_execution = false)
          return if target.dead?
          return if cannot_be_consumed?(force_execution)

          # @type [Battle::Move]
          move = target.moveset.find { |s| s.pp == 0 }
          move ||= target.moveset.reject { |s| s.pp == s.ppmax }.min_by(&:pp)
          move ||= target.moveset.min_by(&:pp)

          if move
            move.pp += 10
            move.pp.clamp(0, move.ppmax)
            @logic.scene.display_message_and_wait(message(target, move))
          end

          consume_berry(target, launcher, skill)
        end

        # Give the message
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move, nil] Potential move used
        # @return String
        def message(target, move)
          return parse_text_with_pokemon(19, 917, target, PFM::Text::ITEM2[1] => data_item(db_symbol).name, PFM::Text::MOVE[2] => move.name)
        end
      end
      register(:leppa_berry, LeppaBerry)
    end
  end
end
