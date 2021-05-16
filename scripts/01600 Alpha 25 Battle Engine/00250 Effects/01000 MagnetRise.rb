module Battle
  module Effects
    # User becomes immune to Ground-type moves for N turns.
    class MagnetRise < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param turncount [Integer] (default: 5)
      def initialize(logic, pokemon, turncount = 5)
        super(logic, pokemon)
        self.counter = turncount
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        :magnet_rise
      end

      # Function called when we try to check if the target evades the move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @return [Boolean] if the target is evading the move
      def on_move_prevention_target(user, target, move)
        return false unless target == @pokemon
        return false unless move.type_ground?

        @logic.scene.display_message_and_wait(on_proc_message)
        return true
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        @logic.scene.display_message_and_wait(on_delete_message)
      end

      private
      
      # Transfer the effect to the given pokemon via baton switch
      # @param with [PFM::Battler] the pokemon switched in
      # @return [Battle::Effects::PokemonTiedEffectBase, nil] the effect to give to the switched in pokemon, nil if there is this effect isn't transferable via baton pass
      def baton_switch_transfer(with)
        return self.class.new(@logic, with)
      end

      # Message displayed when the effect procs
      # @return [String]
      def on_proc_message
        parse_text_with_pokemon(19, 658, @pokemon)
      end

      # Message displayed when the effect wear off
      # @return [String]
      def on_delete_message
        parse_text_with_pokemon(19, 661, @pokemon)
      end
    end
  end
end