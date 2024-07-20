module Battle
  class Move
    class OrderUp < Basic
      COMMANDERS = {
        tatsugiri: {
          forms: [
            { form: 0, stats: { atk: 1 } },
            { form: 1, stats: { dfe: 1 } },
            { form: 2, stats: { spd: 1 } }
          ]
        }
      }

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return user.effects.has?(:commanded)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do
          next unless user.effects.has?(:commanded)

          commanding = logic.allies_of(user).find { |ally| ally.effects.has?(:commanding) }
          next unless commanding

          stats = COMMANDERS.dig(commanding.db_symbol, :forms)&.find { |form| form[:form] == commanding.form }&.dig(:stats)
          next unless stats

          stats.each { |stat, power| logic.stat_change_handler.stat_change_with_process(stat, power, user, user, self) }
        end
      end
    end

    Move.register(:s_order_up, OrderUp)
  end
end
