module Battle
  class Move
    # Class managing Smelling Salts move
    class SmellingSalts < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power * 2 if target.paralyzed?

        return super
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.paralyzed?

          target.cure
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 281, target))
        end
      end
    end
    Move.register(:s_smelling_salt, SmellingSalts)
  end
end
