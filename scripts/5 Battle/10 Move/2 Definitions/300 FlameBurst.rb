module Battle
  class Move
    # Flame Burst deals damage and will also cause splash damage to any Pokémon adjacent to the target.
    class FlameBurst < Basic
      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        super

        actual_targets.each do |actual_target|
          targets = logic.adjacent_allies_of(actual_target)

          targets.each do |target|
            next if target.has_ability?(:magic_guard)

            hp = calc_splash_damage(target)
            logic.damage_handler.damage_change(hp, target)
          end
        end
      end

      private

      # Calculate the damage dealt by the splash
      # @param target [PFM::PokemonBattler] target of the splash
      # @return [Integer]
      def calc_splash_damage(target)
        return (target.max_hp / 16).clamp(1, target.hp)
      end
    end

    register(:s_flame_burst, FlameBurst)
  end
end