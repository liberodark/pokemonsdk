module Battle
  module Effects
    class Item
      class StatusBerry < Berry
        # Function called when a post_status_change is performed
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_status_change(handler, status, target, launcher, skill)
          return if target != @target || status != healed_status

          process_effect(@target, launcher, skill)
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

          consume_berry(target, launcher, skill)
          return unless target.status_effect.name == healed_status

          @logic.status_change_handler.status_change(:cure, target, launcher, skill)
        end

        # Tell which status the berry tries to fix
        # @return [Symbol]
        def healed_status
          return :freeze
        end

        class Rawst < StatusBerry
          # Tell which status the berry tries to fix
          # @return [Symbol]
          def healed_status
            return :burn
          end
        end

        class Pecha < StatusBerry
          # Tell which status the berry tries to fix
          # @return [Symbol]
          def healed_status
            return %i[poison toxic].include?(@target.status_effect.name) ? @target.status_effect.name : false
          end
        end

        class Chesto < StatusBerry
          # Tell which status the berry tries to fix
          # @return [Symbol]
          def healed_status
            return :sleep
          end
        end

        class Cheri < StatusBerry
          # Tell which status the berry tries to fix
          # @return [Symbol]
          def healed_status
            return :paralysis
          end
        end
      end
      register(:aspear_berry, StatusBerry)
      register(:rawst_berry, StatusBerry::Rawst)
      register(:pecha_berry, StatusBerry::Pecha)
      register(:chesto_berry, StatusBerry::Chesto)
      register(:cheri_berry, StatusBerry::Cheri)
    end
  end
end
