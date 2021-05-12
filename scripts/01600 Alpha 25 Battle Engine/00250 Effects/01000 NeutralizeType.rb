module Battle
  module Effects
    # Neutralize Type Effect
    class NeutralizeType < PokemonTiedEffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      # @param target [PFM::PokemonBattler]
      # @param turn_count [Integer]
      def initialize(logic, target, turn_count)
        super(logic, target)
        @target = target
        target.ignore_type(neutralyzed_type)
        self.counter = turn_count
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        log_error('Implementation Error: Name shound be overwritten in child class.')
        return :neutralize_type
      end

      # Get the neutralized type
      # @return [Integer]
      def neutralyzed_type
        log_error('Implementation Error: Neutralized type should be overwritten in child class.')
        return 0
      end

      # Show the message when the effect gets deleted
      def on_delete
        @target.restore_types
      end
    end

    # Class managing Roost Effect
    class Roost < NeutralizeType
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :roost
      end

      # Get the neutralized type
      # @return [Integer]
      def neutralyzed_type
        return GameData::Types::FLYING
      end
    end
  end
end
