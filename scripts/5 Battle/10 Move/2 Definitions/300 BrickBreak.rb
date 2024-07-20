module Battle
  class Move
    # Class managing Brick Break move
    class BrickBreak < BasicWithSuccessfulEffect
      private

      WALLS = %i[light_screen reflect aurora_veil]

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        bank = actual_targets.map(&:bank).first
        @logic.bank_effects[bank].each do |effect|
          next unless WALLS.include?(effect.name)

          case effect.name
          when :reflect
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 132 : 133))
          when :light_screen
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 136 : 137))
          else
            @scene.display_message_and_wait(parse_text(18, bank == 0 ? 140 : 141))
          end
          log_info("PSDK Brick Break: #{effect.name} effect removed.")
          effect.kill
        end
      end
    end

    class RagingBull < BrickBreak
      # @return [Array<Symbol]
      RAGING_BULL_USERS = %i[tauros]

      # Get the types of the move with 1st type being affected by effects
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Array<Integer>] list of types of the move
      def definitive_types(user, target)
        return [type] unless RAGING_BULL_USERS.include?(user.db_symbol)

        case user.form
        when 1
          return [data_type(:fighting).id]
        when 2
          return [data_type(:fire).id]
        when 3
          return [data_type(:water).id]
        else
          return [type]
        end
      end
    end

    Move.register(:s_brick_break, BrickBreak)
    Move.register(:s_raging_bull, RagingBull)
  end
end
