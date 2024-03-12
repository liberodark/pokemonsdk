module Battle
  module Effects
    # TarShot Effect
    class TarShot < PokemonTiedEffectBase
      # Choose the type to add as a weakness according to the move_db_symbol used to add this weakness
      ADD_WEAKNESS_TO = {
        tar_shot: :fire
      }
      # Create a new TarShot effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param origin_move [Symbol] the move that caused this effect
      def initialize(logic, target, origin_move)
        super(logic, target)
        @factor05 = []
        @factor1 = []
        @factor2 = []
        @origin_move = origin_move
      end

      # Function that computes an overwrite of the type multiplier
      # @param target [PFM::PokemonBattler]
      # @param target_type [Integer] one of the type of the target
      # @param type [Integer] one of the type of the move
      # @param move [Battle::Move]
      # @return [Float, nil] overwriten type multiplier
      def on_single_type_multiplier_overwrite(target, target_type, type, move)
        return if target != @pokemon
        return unless target_type == target.type1
        return if move.type != data_type(ADD_WEAKNESS_TO[@origin_move]).id

        @factor05.clear ; @factor1.clear ; @factor2.clear

        type_check(ADD_WEAKNESS_TO[@origin_move])

        return 1 if @factor05.include?(target_type)
        return 2 if @factor1.include?(target_type)
        return 4 if @factor2.include?(target_type)

        return nil
      end

      # Compare the added type weakness with all other types
      # @param type_added [Integer] type added by the move that caused this effect
      def type_check(type_added)
        each_data_type.each do |type|
          factor = data_type(type_added).hit(type.db_symbol) <=> 1

          case factor
          when -1
            @factor05 << type.id
          when 1
            @factor2 << type.id
          else
            @factor1 << type.id
          end
        end

        return
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :tar_shot
      end
    end
  end
end
