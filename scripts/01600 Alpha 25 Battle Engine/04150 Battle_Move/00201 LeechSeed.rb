module Battle
  class Move
    # Move that inflict leech seed to the ennemy
    class LeechSeed < Move
      private

      # Test if the target is immune
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(target)
        return true if target.effects.has?(:leech_seed_mark) || target.type_grass?

        return super
      end

      # Internal procedure of the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note THIS IS REWRITTEN BECAUSE THE NORMAL PROCEDURE IS NOT DONE!
      # @todo remove this and rely on super class
      def proceed_internal(user, targets)
        return unless move_usable_by_user(user, targets)

        usage_message(user)
        return scene.display_message(parse_text(18, 74)) if rand(100) >= accuracy

        actual_targets = accuracy_immunity_test(user, targets) # => Will call $scene.dislay_message for each accuracy fail
        return if actual_targets.none?

        play_animation(user, targets)

        deal_effect(user, actual_targets)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          @logic.add_position_effect(Effects::LeechSeed.new(@logic, user, target))
          @scene.display_message(parse_text_with_pokemon(19, 607, target))
        end
      end
    end

    Move.register(:s_leech_seed, LeechSeed)
  end
end
