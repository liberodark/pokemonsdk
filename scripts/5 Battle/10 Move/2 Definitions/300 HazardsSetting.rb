module Battle
  class Move
    # Adds a layer of Stealth Rocks to the target if it lands.
    class StoneAxe < Basic
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        bank = actual_targets.map(&:bank).first

        return if @logic.bank_effects[bank]&.get(:stealth_rock)

        @logic.add_bank_effect(Effects::StealthRock.new(@logic, bank, self))
        @scene.display_message_and_wait(parse_text(18, bank == 0 ? 162 : 163))
      end

      # Calculate the multiplier needed to get the damage factor of the Stealth Rock
      # @param target [PFM::PokemonBattler]
      # @return [Integer, Float]
      def calc_factor(target)
        type = [self.type]
        @effectiveness = -1
        n = calc_type_n_multiplier(target, :type1, type) *
            calc_type_n_multiplier(target, :type2, type) *
            calc_type_n_multiplier(target, :type3, type)
        return n
      end
    end

    # Adds a layer of Spikes to the target if it lands.
    class CeaselessEdge < Basic
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        bank = actual_targets.map(&:bank).first

        return if @logic.bank_effects[bank]&.get(:spikes)&.max_power?

        if (effect = @logic.bank_effects[bank]&.get(:spikes))
          effect.empower
        else
          @logic.add_bank_effect(Effects::Spikes.new(@logic, bank))
        end
        @scene.display_message_and_wait(parse_text(18, bank == 0 ? 154 : 155))
      end
    end
    Move.register(:s_stone_axe, StoneAxe)
    Move.register(:s_ceaseless_edge, CeaselessEdge)
  end
end
