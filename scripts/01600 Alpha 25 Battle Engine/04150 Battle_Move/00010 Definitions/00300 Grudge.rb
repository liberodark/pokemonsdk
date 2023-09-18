module Battle
  class Move
    # Class managing Grudge move
    class Grudge < Move
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.all? { |target| !target.effects.has?(:grudge) }
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:grudge)

          target.effects.add(Effects::Grudge.new(@logic, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 632, target))
        end
      end
    end
    Move.register(:s_grudge, Grudge)
  end
end
