module Battle
  # Module responsive of storing all the effects of the battle engine
  module Effects
    # Class responsive of handling the effects active on something (terrain, pokemon, bank position)
    class EffectsHandler
      # Create a new effect handler
      def initialize
        # List of all the effects
        # @type [Array<Battle::Effects::EffectBase>]
        @effects = []
      end

      # Update the counter of all effects
      def update_counter
        @effects.each(&:update_counter)
        deleted_dead_effects
      end

      # Tell if an effect is present
      # @param name [Symbol] name of the effect
      # @return [Boolean] if the effect is present
      def has?(name)
        return @effects.any? { |e| e.name == name }
      end

      # Add an effect
      # @param effect [EffectBase]
      def add(effect)
        @effects.push(effect)
      end

      # Get an effect using its name
      # @param name [Symbol]
      # @return [EffectBase, nil]
      def get(name)
        @effects.find { |e| e.name == name }
      end

      # Call something on all effects
      # @param block [Proc] block that is called for the each process
      # @yieldparam effect [Battle::Effects::EffectBase]
      # @note automatically calls deleted_dead_effects if a block is given
      def each(&block)
        return @effects.each unless block_given?

        @effects.each(&block)
        deleted_dead_effects
      end

      # Delete all the effect that should be deleted
      def deleted_dead_effects
        deleted_effect = @effects.select(&:dead?)
        return if deleted_effect.empty?

        @effects.reject!(&:dead?)
        deleted_effect.each(&:on_delete)
      end

      # Delete specific dead effect
      # @param name [Symbol]
      def delete_specific_dead_effect(name)
        deleted_effect = @effects.select { |effect| effect.dead? && effect.name == name }
        return if deleted_effect.empty?

        @effects.reject! { |effect| effect.dead? && effect.name == name }
        deleted_effect.each(&:on_delete)
      end
    end
  end
end
