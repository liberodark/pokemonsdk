module Battle
  module Effects
    class ShellTrap < PokemonTiedEffectBase
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
        return if target != @pokemon
        return unless skill&.physical?
        return if launcher.nil? || launcher == target || launcher.bank == target.bank
        return if launcher.has_ability?(:sheer_force) && launcher.ability_effect.activated?

        actions = handler.logic.actions
        action_index = actions.find_index { |action| action.is_a?(Actions::Attack) && action.launcher == @pokemon }
        return unless action_index

        action = actions.delete_at(action_index)
        actions.push(action)

        kill
        @pokemon.effects.delete_specific_dead_effect(:shell_trap)
      end


      # Get the name of the effect
      # @return [Symbol]
      def name
        return :shell_trap
      end
    end
  end
end
