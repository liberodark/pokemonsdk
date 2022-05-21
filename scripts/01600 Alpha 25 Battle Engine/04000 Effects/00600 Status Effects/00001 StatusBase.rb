module Battle
  module Effects
    class Status < EffectBase
      # Get the target of the effect
      # @return [PFM::PokemonBattler]
      attr_reader :target

      @registered_statuses = {}

      # Create a new status effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param status [Symbol] Symbol of the status
      def initialize(logic, target, status)
        super(logic)
        @target = target
        @status = status
      end

      # Get the ID of the status
      # @return [Integer]
      def status_id
        Configs.states.ids[@status] || -1
      end

      # Tell if the status effect is poisoning
      # @return [Boolean]
      def poison?
        @status == :poison
      end

      # Tell if the status effect is paralysis
      # @return [Boolean]
      def paralysis?
        @status == :paralysis
      end

      # Tell if the status effect is burn
      # @return [Boolean]
      def burn?
        @status == :burn
      end

      # Tell if the status effect is asleep
      # @return [Boolean]
      def asleep?
        @status == :sleep
      end

      # Tell if the status effect is frozen
      # @return [Boolean]
      def frozen?
        @status == :freeze
      end

      # Tell if the status effect is toxic
      # @return [Boolean]
      def toxic?
        @status == :toxic
      end

      # Tell if the effect is a global poisoning effect (poison or toxic)
      # @return [Boolean]
      def global_poisoning?
        poison? || toxic?
      end

      class << self
        # Register a new status
        # @param status [Symbol] Symbol of the status
        # @param klass [Class<Status>] class of the status effect
        def register(status, klass)
          @registered_statuses[status] = klass
        end

        # Create a new Status effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param status [Symbol] Symbol of the status
        # @return [Status]
        def new(logic, target, status)
          klass = @registered_statuses[status] || Status
          object = klass.allocate
          object.send(:initialize, logic, target, status)
          return object
        end
      end
    end
  end
end
