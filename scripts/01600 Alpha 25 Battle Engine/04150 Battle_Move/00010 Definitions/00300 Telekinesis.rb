module Battle
  class Move
    class Telekinesis < Move
      # @type [Array<Symbol>]
      POKEMON_UNAFFECTED = %i[diglett dugtrio sandygast palossand]
      # @type [Array<Symbol>]
      EFFECTS_TO_CHECK = %i[telekinesis ingrain smack_down]
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if EFFECTS_TO_CHECK.any? { |effect_name| targets.all? { |target| target.effects.has?(effect_name) } }
        return show_usage_failure(user) && false if @logic.terrain_effects.has?(:gravity)
      
        return true
      end

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true if target.db_symbol == :gengar && target.form == 30
        return true if POKEMON_UNAFFECTED.include?(target.db_symbol)

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if EFFECTS_TO_CHECK.any? { |effect_name| target.effects.has?(effect_name) }

          target.effects.add(Effects::Telekinesis.new(logic, target, turn_count))
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 1146, target))
        end
      end

      private

      # Return the number of turns the effect works
      # @return [Integer]
      def turn_count
        return 3
      end

      # Name of the effect
      # @return [Symbol]
      def effect_name
        return :telekinesis
      end
    end
    Move.register(:s_telekinesis, Telekinesis)
  end
end