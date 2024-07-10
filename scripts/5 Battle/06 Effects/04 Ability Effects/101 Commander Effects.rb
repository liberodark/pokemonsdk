module Battle
  module Effects
    class Commanding < OutOfReachBase
      include Mechanics::ForceNextMove

      def initialize(logic, pokemon)
        super(logic, pokemon, nil, [], Float::INFINITY)
        @pokemon = pokemon
        logic.actions.reject! do |a|
          a.is_a?(Actions::Switch) && Actions::Switch.from(a).who == @pokemon
        end
      end

      # Make the empty action that is forced by this effect
      # @return [Actions::NoAction]
      def make_action
        return Actions::NoAction.new(@logic.scene)
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon

        return :prevent
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @param reason [Symbol] the reason why the SwitchHandler is called
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill, reason)
        return if pokemon != @pokemon

        return handler.prevent_change do
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 878, @pokemon))
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :commanding
      end
    end

    class Commanded < PokemonTiedEffectBase
      def initialize(logic, pokemon, ally)
        super(logic, pokemon)
        @pokemon = pokemon
        @origin = ally
        logic.actions.reject! do |a|
          a.is_a?(Actions::Switch) && Actions::Switch.from(a).who == @pokemon
        end
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @param reason [Symbol] the reason why the SwitchHandler is called
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill, reason)
        return if pokemon != @pokemon

        return handler.prevent_change do
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 878, @pokemon))
        end
      end

      # Function called after damages were applied and when target died (post_damage_death)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, hp, target, launcher, skill)
        return if target != @pokemon
        return unless @origin&.can_fight?

        @origin.effects.get(:commanding)&.kill
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :commanded
      end
    end
  end
end
