module Battle
  class Move
    # Move that makes possible to hit Ghost type Pokemon with Normal or Fighting type moves
    class Nightmare < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        return show_usage_failure(user) && false if targets.none? { |target| target.asleep? && target.has_ability?(:comatose) }
        return show_usage_failure(user) && false if targets.all? { |target| target.effects.has?(:nightmare) }

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.asleep?
          next if target.effects.has?(:nightmare)

          target.effects.add(Effects::Nightmare.new(@logic, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 321, target))
        end
      end
    end

    Move.register(:s_nightmare, Nightmare)
  end
end
