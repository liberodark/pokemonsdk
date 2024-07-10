module Battle
  module Effects
    class FieldTerrain < EffectBase
      # Get the db_symbol of the field terrain
      # @return [Symbol]
      attr_reader :db_symbol
      # Get the counter of the field terrain
      # @return [Integer]
      attr_accessor :internal_counter

      @registered_field_terrains = {}

      # Create a new field terrain effect
      # @param logic [Battle::Logic]
      # @param db_symbol [Symbol] db_symbol of the field terrain
      def initialize(logic, db_symbol)
        super(logic)
        @db_symbol = db_symbol
        @internal_counter = Float::INFINITY
      end

      # Tell if the field terrain is none
      # @return [Boolean]
      def none?
        return @db_symbol == :none
      end

      # Tell if the field terrain is electric
      # @return [Boolean]
      def electric?
        return @db_symbol == :electric_terrain
      end

      # Tell if the field terrain is grassy
      # @return [Boolean]
      def grassy?
        return @db_symbol == :grassy_terrain
      end

      # Tell if the field terrain is psychic
      # @return [Boolean]
      def psychic?
        return @db_symbol == :psychic_terrain
      end

      # Tell if the field terrain is psychic
      # @return [Boolean]
      def misty?
        return @db_symbol == :misty_terrain
      end

      class << self
        # Register a new field terrain
        # @param db_symbol [Symbol] db_symbol of the field terrain
        # @param klass [Class<Field terrain>] class of the field terrain effect
        def register(db_symbol, klass)
          @registered_field_terrains[db_symbol] = klass
        end

        # Create a new Field terrain effect
        # @param logic [Battle::Logic]
        # @param db_symbol [Symbol] db_symbol of the field terrain
        # @return [Field terrain]
        def new(logic, db_symbol)
          klass = @registered_field_terrains[db_symbol] || FieldTerrain
          object = klass.allocate
          object.send(:initialize, logic, db_symbol)
          return object
        end
      end
    end
  end
end
