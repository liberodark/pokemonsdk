module Battle
  module Effects
    # Implement the Beak Blast effect
    class BeakBlast < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super
        self.counter = 1
      end

      # Function called after damages were applied (post_damage, when target is still alive)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage(handler, hp, target, launcher, skill)
        return unless launcher != @pokemon
        return unless skill&.direct? && launcher && launcher.hp > 0 && launcher.can_be_burn? && !launcher.has_ability?(:long_reach)
        return if @pokemon.move_history.any? { |history| history.turn == $game_temp.battle_turn }

        handler.logic.status_change_handler.status_change_with_process(:burn, launcher, target)
      end

      # Function called after damages were applied and when target died (post_damage_death)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, hp, target, launcher, skill)
        return unless launcher != @pokemon
        return unless skill&.direct? && launcher && launcher.hp > 0 && launcher.can_be_burn? && !launcher.has_ability?(:long_reach)
        return if @pokemon.move_history.any? { |history| history.turn == $game_temp.battle_turn }

        handler.logic.status_change_handler.status_change_with_process(:burn, launcher, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :beak_blast
      end
    end
  end
end
