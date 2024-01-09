module Battle
  class Move
    class MagnetRise < Move
      # @type [Array<Symbol>]
      EFFECTS_TO_CHECK = %i[magnet_rise ingrain smack_down]
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if EFFECTS_TO_CHECK.any? { |effect_name| targets.all? { |target| target.effects.has?(effect_name) } }
        return show_usage_failure(user) && false if targets.all? { |target| target.hold_item?(:iron_ball) }
        return show_usage_failure(user) && false if @logic.terrain_effects.has?(:gravity)
      
        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if EFFECTS_TO_CHECK.any? { |effect_name| target.effects.has?(effect_name) }
          next if target.hold_item?(:iron_ball)

          target.effects.add(Effects::MagnetRise.new(logic, target, turn_count))
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 658, target))
        end
      end

      # Return the number of turns the effect works
      # @return [Integer]
      def turn_count
        return 5
      end
    end
    Move.register(:s_magnet_rise, MagnetRise)
  end
end