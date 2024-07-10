module Battle
  class Move
    class SappySeed < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any? { |target| can_affect_target?(target) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless can_affect_target?(target)

          @logic.add_position_effect(Effects::LeechSeed.new(@logic, user, target))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 607, target))
        end
      end

      private

      # Check if the effect can affect the target
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def can_affect_target?(target)
        return false if target.dead? || target.type_grass?
        return false if target.effects.has? { |effect| %i[leech_seed_mark substitute].include?(effect.name) }
      
        return true
      end
      
    end
    Move.register(:s_sappy_seed, SappySeed)
  end
end
