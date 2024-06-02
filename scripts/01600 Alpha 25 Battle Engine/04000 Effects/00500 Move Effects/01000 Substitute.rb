module Battle
  module Effects
    # Implement the Substitute effect
    class Substitute < PokemonTiedEffectBase
      # Get the substitute hp
      # @return [Integer]
      attr_accessor :hp
      # Get the substitute max hp
      attr_reader :max_hp

      # @return [Array<Symbol>]
      CANT_IGNORE_SUBSTITUTE = %i[transform sky_drop]

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super
        @hp = @max_hp = pokemon.max_hp / 4
        pokemon.effects.get(:bind).kill if pokemon.effects.has?(:bind)
        logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).temporary_substitute_overwrite = false
      end

      # Function called when a stat_increase_prevention is checked
      # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the stat increase cannot apply
      def on_stat_increase_prevention(handler, stat, target, launcher, skill)
        return if target != @pokemon
        return :prevent if target != launcher && skill && !skill.authentic?

        return nil
      end

      # Function called when a stat_decrease_prevention is checked
      # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the stat decrease cannot apply
      def on_stat_decrease_prevention(handler, stat, target, launcher, skill)
        return if target != @pokemon
        return :prevent if target != launcher && skill && !skill.authentic?

        return nil
      end

      # Function called when a damage_prevention is checked
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
      def on_damage_prevention(handler, hp, target, launcher, skill)
        return if target != @pokemon
        return if skill.nil? || skill.authentic?
        return if launcher.nil? || launcher.has_ability?(:infiltrator) && CANT_IGNORE_SUBSTITUTE.none?(skill.db_symbol)

        return handler.prevent_change do
          @hp -= hp
          if @hp <= 0
            kill
            target.effects.delete_specific_dead_effect(:substitute)
            handler.scene.visual.show_switch_form_animation(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 794, target))
          else
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 791, target))
          end
        end
      end

      # Function called when a status_prevention is checked
      # @param handler [Battle::Logic::StatusChangeHandler]
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the status cannot be applied
      def on_status_prevention(handler, status, target, launcher, skill)
        return if target != @pokemon || !skill || status == :cure || launcher == target
        return if skill.authentic?

        return handler.prevent_change do
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 24, target))
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :substitute
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return reset_user_sprite
      end

      # Function called at the end of an action
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_post_action_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead? || @pokemon.effects.has?(:out_of_reach_base)

        action = logic.current_action
        return unless action.is_a?(Actions::Attack) && !action.move.is_a?(Move::BatonPass)
        return if action.launcher != @pokemon && action.move.is_a?(Move::Substitute)
        return unless logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).temporary_substitute_overwrite

        play_substitute_animation(:to)
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        return unless with == @pokemon
        return unless with.effects.has?(:substitute)

        play_substitute_animation(:to)
      end

      # Play the right Substitute animation depending on the given reason
      # @param reason [Symbol] :to => from sprite to substitute, :from => from substitute to sprite
      def play_substitute_animation(reason = :from)
        method_name = reason == :from ? :switch_from_substitute_animation : :switch_to_substitute_animation
        @logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).temporary_substitute_overwrite = (reason == :from)
        return direct_sprite_change(method_name) unless $options.show_animation

        @logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).send(method_name)
        @logic.scene.visual.wait_for_animation
      end

      # Applies the sprite change directly
      # @param method_name [Symbol] :switch_from_substitute_animation, :switch_to_substitute_animation
      def direct_sprite_change(method_name)
        return @logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).switch_to_substitute_sprite if method_name == :switch_to_substitute_animation

        return reset_user_sprite
      end

      # Force the reset of the user's sprite to its original sprite
      def reset_user_sprite
        return @logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).send(:load_battler, true)
      end

      private

      # Transfer the effect to the given pokemon via baton switch
      # @param with [PFM::Battler] the pokemon switched in
      # @return [Battle::Effects::PokemonTiedEffectBase, nil] the effect to give to the switched in pokemon, nil if there is this effect isn't transferable via baton pass
      def baton_switch_transfer(with)
        return self.class.new(@logic, with)
      end
    end
  end
end
