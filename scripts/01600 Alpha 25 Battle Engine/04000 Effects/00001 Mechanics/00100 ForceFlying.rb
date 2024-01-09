module Battle
  module Effects
    module Mechanics
      # Effect mechanics that make the pokemon flies
      # When including this mechanics :
      # - overwrite on_proc_message
      # - overwrite on_delete_message
      # - call Effects::Mechanics::ForceFlying.register_force_flying_hook in the class
      module ForceFlying
        # Create a new Pokemon tied effect
        # @param pokemon [PFM::PokemonBattler]
        # @param name [Symbol] giving the name of the effect
        # @param duration [Integer] duration of the effect (including the current turn)
        def force_flying_initialize(pokemon, name, duration)
          @pokemon = pokemon
          @name = name
          self.counter = duration
        end

        # Function called when the effect has been deleted from the effects handler
        def on_delete
          return unless (effect_message = on_delete_message)

          return @logic.scene.display_message_and_wait(effect_message)
        end
        alias force_flying_on_delete on_delete

        private

        # Transfer the effect to the given pokemon via baton switch
        # @param with [PFM::PokemonBattler] the pokemon switched in
        # @return [Battle::Effects::PokemonTiedEffectBase, nil] the effect to give to the switched in pokemon, nil if there is this effect isn't transferable via baton pass
        def baton_switch_transfer(with)
          return self.class.new(@logic, with)
        end
        alias force_flying_baton_switch_transfer baton_switch_transfer

        # Message displayed when the effect wear off
        # @return [String, nil]
        def on_delete_message
          nil
        end

        class << self
          # Make to pokemon flying in grounded? test
          # @param reason [String] reason of the hook
          # @param name [Symbol] name of the effect
          def register_force_flying_hook(reason, name)
            PFM::PokemonBattler.register_force_flying_hook(reason) do |pokemon|
              next pokemon.effects.has?(name)
            end
          end
        end
      end
    end
  end
end
