module Battle
  module Effects
    # Implement the Out of Reach effect
    class OutOfReach < PokemonTiedEffectBase
      # List of move that can hit a Pokemon when he's out of reach
      #   CAN_HIT_BY_TYPE[oor_type] = [move db_symbol list]
      CAN_HIT_BY_TYPE = [
        [], # Nothing
        %i[earthquake fissure magnitude], # Dig
        %i[gust whirlwind thunder swift sky_uppercut twister smack_down hurricane thousand_arrows], # Fly
        %i[surf whirlpool], # Dive
        [] # Phantom force / Shadow Force
      ]
      # Out of reach moves to type
      #   OutOfReach[sb_symbol] => oor_type
      TYPES = { dig: 1, fly: 2, dive: 3, bounce: 2, phantom_force: 4, shadow_force: 4, sky_drop: 2 }
      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param type [Integer] type of Out of reach
      def initialize(logic, target, type)
        super(logic, target)
        @type = type
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :out_of_reach
      end

      # Function called when we try to check if the target evades the move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @return [Boolean] if the target is evading the move
      def on_move_prevention_target(user, target, move)
        return false if target != @pokemon

        return !(CAN_HIT_BY_TYPE[@type] || []).include?(move.db_symbol)
      end
    end
  end
end
