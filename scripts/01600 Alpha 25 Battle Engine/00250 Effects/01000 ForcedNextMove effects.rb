module Battle
  module Effects
    # Forced Next Move that can be disturbed
    class ForceNextMoveDisturbable < PokemonTiedEffectBase
      include ForceNextMove
      include Disturbable

      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param counter [Integer] number of turn the move is forced to be used
      # @param targets [Array<PFM::PokemonBattler>]
      def initialize(logic, target, move, targets, counter = 2)
        super(logic, target)
        init_force_next_move(move, targets, counter)
        init_disturbable()
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        :force_next_move_disturbable
      end
    end

    # Forced Next Move for rollout so it stores additional information
    class Rollout < PokemonTiedEffectBase
      include ForceNextMove
      include SuccessiveSuccessfulUses

      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param counter [Integer] number of turn the move is forced to be used
      # @param targets [Array<PFM::PokemonBattler>]
      # @param turncount [Integer] (default: 5) number of turn the effect proc (including the current one)
      def initialize(logic, target, move, targets, turncount = 2)
        super(logic, target)
        init_force_next_move(move, targets, turncount)
        init_successive_successful_uses(target, move)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        :rollout
      end
    end

    # Forced Next Move for Bide
    class Bide < PokemonTiedEffectBase
      include ForceNextMove

      # Get the number of damage the Pokemon got during this effect
      # @return [Integer]
      attr_accessor :damages

      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param counter [Integer] number of turn the move is forced to be used (including the current one)
      # @param targets [Array<PFM::PokemonBattler>]
      def initialize(logic, target, move, targets, counter = 2)
        super(logic, target)
        init_force_next_move(move, targets, counter)
        @damages = 0
      end

      # Function called after damages were applied (post_damage, when target is still alive)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage(handler, hp, target, launcher, skill)
        return if @pokemon != target || hp < 0

        @damages += hp
      end

      # Tell if the bide can unleach
      # @return [Boolean]
      def unleach?
        return @counter == 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        :bide
      end
    end
  end
end
