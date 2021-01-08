module Battle
  class Logic
    # Handler responsive of processing flee attempt
    class FleeHandler < ChangeHandlerBase
      include Hooks

      # Try to flee
      # @param index [Integer] index of the Pokemon on the trainer bank
      # @note flee_block hooks are called to test if the flee is blocked for other reason than switch blocked
      # @return [Symbol] if success :success, if failure :failure, if blocked (trainer battle) :blocked
      def attempt(index)
        exec_hooks(FleeHandler, :flee_block, binding)
        switch_handler = @logic.switch_handler
        unless switch_handler.can_switch?(@logic.battler(0, index))
          switch_handler.process_prevention_reason
          return :failure
        end
        value = flee_value(index)
        @logic.battle_info.flee_attempt_count += 1
        result = rand(256) < value ? :success : :failure
        @scene.display_message(parse_text(18, result == :success ? 75 : 76))
        return result
      rescue Hooks::ForceReturn => e
        process_prevention_reason
        return e.data
      end

      private

      # Get the value used to test if the flee is successfull
      # @param index [Integer] index of the Pokemon on the trainer bank
      # @return [Integer]
      def flee_value(index)
        trainer_poke = @logic.battler(0, index)
        enemy_poke = @logic.battler(1, index) || @logic.battler(1, 0)

        a = trainer_poke&.base_spd || 1
        b = (enemy_poke&.base_spd || 1).clamp(1, Float::INFINITY)
        c = @logic.battle_info.flee_attempt_count + 1
        log_debug("flee_value: a = #{a}, b = #{b}, c = #{c}")
        return ((a * 128 / b) + 30 * c) % 256
      end

      class << self
        # Function that registers a flee_block hook
        # @param reason [String] reason of the flee_block registration
        # @yieldparam handler [FleeHandler]
        # @yieldreturn [:prevent, nil] :prevent if the stat increase cannot apply
        def register_flee_block_hook(reason)
          Hooks.register(FleeHandler, :flee_block, reason) do
            result = yield(
              self
            )
            force_return(:blocked) if result == :prevent
          end
        end
      end

      FleeHandler.register_flee_block_hook('No flee in trainer battle') do |handler|
        next unless handler.logic.battle_info.trainer_battle?

        next handler.prevent_change do
          handler.scene.display_message(parse_text(18, 79))
        end
      end

      FleeHandler.register_flee_block_hook('No flee when BT_NoEscape is on') do |handler|
        next unless $game_switches[Yuki::Sw::BT_NoEscape]

        handler.prevent_change do
          handler.scene.display_message(parse_text(18, 77))
        end
      end
    end
  end
end
