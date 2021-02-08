module Battle
  class Logic
    # Handler responsive of answering properly terrain changes requests
    class FTerrainChangeHandler < ChangeHandlerBase
      include Hooks
      # Mapping between terrain symbol & terrain ID
      FTERRAIN_SYM_TO_ID = {
        terrainnone: 0,
        electric_terrain: 1,
        grassy_terrain: 2,
        misty_terrain: 3,
        psychic_terrain: 4,
      }
      # Weather thingies copiepasted, I don't think this is really useful right now
      FTERRAIN_SYM_TO_MSG = {
        terrainnone: 97,
        electric: 88,
        grassy: 87,
        mist: 89,
        psychic: 90,
      }
      # Function telling if a terrain can be applyied
      # @param fterrain_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
      # @return [Boolean]
      def fterrain_appliable?(fterrain_type)
        log_data("# fterrain_appliable?(#{fterrain_type})")
        reset_prevention_reason
        last_fterrain = FTERRAIN_SYM_TO_ID.key($env.current_fterrain) || :terrainnone
        exec_hooks(FTerrainChangeHandler, :fterrain_prevention, binding)
        return true
      rescue Hooks::ForceReturn => e
        log_data("# FR: fterrain_appliable? #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      end

      # Function that actually change the terrain
      # @param fterrain_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
      # @param nb_turn [Integer, nil] Number of turn, use nil for Infinity
      def fterrain_change(fterrain_type, nb_turn)
        log_data("# fterrain_change(#{fterrain_type}, #{nb_turn})")
        last_fterrain = FTERRAIN_SYM_TO_ID.key($env.current_fterrain) || :terrainnone
        $env.apply_fterrain(FTERRAIN_SYM_TO_ID[fterrain_type] || 0, nb_turn)
        exec_hooks(FTerrainChangeHandler, :post_fterrain_change, binding)
      rescue Hooks::ForceReturn => e
        log_data("# FR: fterrain_change #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      end

      # Function that test if the change is possible and perform the change if so
      # @param fterrain_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
      # @param nb_turn [Integer, nil] Number of turn, use nil for Infinity
      def fterrain_change_with_process(fterrain_type, nb_turn)
        return process_prevention_reason unless fterrain_appliable?(fterrain_type)

        fterrain_change(fterrain_type, nb_turn)
      end

      private

      # Show the terrain  message
      # @param last_fterrain [Symbol]
      # @param current_fterrain [Symbol]
      def show_fterrain_message(last_fterrain, current_fterrain)
        return if last_fterrain == current_fterrain

        if last_fterrain == :terrainnone
          @scene.display_message_and_wait(parse_text(18, FTERRAIN_SYM_TO_MSG[current_fterrain]))
        elsif current_fterrain == :terrainnone
          @scene.display_message_and_wait(parse_text(18, FTERRAIN_SYM_TO_MSG[current_fterrain]))
        end
      end

      class << self
        # Function that registers a fterrain_prevetion hook
        # @param reason [String] reason of the fterrain_prevetion registration
        # @yieldparam handler [FTerrainChangeHandler]
        # @yieldparam fterrain_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @yieldparam last_fterrain [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @yieldreturn [:prevent, nil] :prevent if the status cannot be applied
        def register_fterrain_prevention_hook(reason)
          Hooks.register(FTerrainChangeHandler, :fterrain_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:fterrain_type),
              hook_binding.local_variable_get(:last_fterrain)
            )
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_fterrain_handler hook
        # @param reason [String] reason of the post_fterrain_handler registration
        # @yieldparam handler [FTerrainChangeHandler]
        # @yieldparam fterrain_type [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @yieldparam last_fterrain [Symbol] :terrainnone, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def register_post_fterrain_change_hook(reason)
          Hooks.register(FTerrainChangeHandler, :post_fterrain_change, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:fterrain_type),
              hook_binding.local_variable_get(:last_fterrain)
            )
          end
        end
      end
    end

    FTerrainChangeHandler.register_fterrain_prevention_hook('PSDK prev field terrain: Effects') do |handler, fterrain_type, last_fterrain|
      next handler.logic.each_effects do |e|
        next e.on_fterrain_prevention(handler, fterrain_type, last_fterrain)
      end
    end
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Effects') do |handler, fterrain_type, last_fterrain|
      next handler.logic.each_effects do |e|
        next e.on_post_fterrain_change(handler, fterrain_type, last_fterrain)
      end
    end

    FTerrainChangeHandler.register_fterrain_prevention_hook('PSDK prev field terrain: Duplicate field terrain') do |_, fterrain, prev|
      next if fterrain != prev

      next :prevent
    end

    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Ensure form switch on field terrain') do |handler|
      handler.logic.all_alive_battlers.each do |battler|
        next unless battler.form_calibrate(:fterrain)

        handler.scene.visual.show_switch_form_animation(battler)
      end
    end

    # Mimicry - No Terrain
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Restart Mimicry type') do |handler, fterrain|
    next unless fterrain == :terrainnone
    mimicries = handler.logic.all_alive_battlers.select { |battler| battler.has_ability?(:mimicry) }
      mimicries.each do |mimicry|
        handler.scene.visual.show_ability(mimicry)
        mimicry.type1 = mimicry.data.type1
        mimicry.type2 = mimicry.data.type2
      end
    end

    # Mimicry - Psychic Terrain
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Psychic Mimicry type') do |handler, fterrain|
    next unless fterrain == :psychic_terrain
    mimicries = handler.logic.all_alive_battlers.select { |battler| battler.has_ability?(:mimicry) }
      mimicries.each do |mimicry|
        handler.scene.visual.show_ability(mimicry)
        mimicry.type1 = 11
        mimicry.type2 = 0
      end
    end

    # Mimicry - Misty Terrain
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Misty Mimicry type') do |handler, fterrain|
    next unless fterrain == :misty_terrain
    mimicries = handler.logic.all_alive_battlers.select { |battler| battler.has_ability?(:mimicry) }
      mimicries.each do |mimicry|
        handler.scene.visual.show_ability(mimicry)
        mimicry.type1 = 18
        mimicry.type2 = 0
      end
    end

    # Mimicry - Grassy Terrain
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Grassy Mimicry type') do |handler, fterrain|
    next unless fterrain == :grassy_terrain
    mimicries = handler.logic.all_alive_battlers.select { |battler| battler.has_ability?(:mimicry) }
      mimicries.each do |mimicry|
        handler.scene.visual.show_ability(mimicry)
        mimicry.type1 = 5
        mimicry.type2 = 0
      end
    end

    # Mimicry - Electric Terrain
    FTerrainChangeHandler.register_post_fterrain_change_hook('PSDK post field terrain: Electric Mimicry type') do |handler, fterrain|
      next unless fterrain == :electric_terrain
      mimicries = handler.logic.all_alive_battlers.select { |battler| battler.has_ability?(:mimicry) }
      mimicries.each do |mimicry|
        handler.scene.visual.show_ability(mimicry)
        mimicry.type1 = 4
        mimicry.type2 = 0
      end
    end
  end
end
