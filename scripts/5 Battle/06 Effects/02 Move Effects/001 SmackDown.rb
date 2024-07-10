module Battle
  module Effects
    # SmackDown Effect
    class SmackDown < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super

        kill_flying_effects(pokemon)
      end

      # Function that computes an overwrite of the type multiplier
      # @param target [PFM::PokemonBattler]
      # @param target_type [Integer] one of the type of the target
      # @param type [Integer] one of the type of the move
      # @param move [Battle::Move]
      # @return [Float, nil] overwriten type multiplier
      def on_single_type_multiplier_overwrite(target, target_type, type, move)
        return unless target_type == data_type(:flying).id
        return unless type == data_type(:ground).id

        return 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :smack_down
      end

      # kill effects that force pokemon to fly
      # @param pokemon [PFM::PokemonBattler]
      def kill_flying_effects(pokemon)
        pokemon.effects.get(:magnet_rise)&.kill
        pokemon.effects.get(:telekinesis)&.kill
        
        if %i[bounce fly].include?(pokemon.effects.get(:out_of_reach_base)&.move&.db_symbol)
          pokemon.effects.get(&:out_of_reach?)&.kill
          pokemon.effects.get(&:force_next_move?)&.kill
        end
      end
    end
  end
end
