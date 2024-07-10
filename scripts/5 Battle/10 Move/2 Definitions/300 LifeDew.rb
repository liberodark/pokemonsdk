module Battle
  class Move
    # Class describing a move that heals the user and its allies
    class LifeDew < HealMove
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          hp = target.max_hp / 4
          logic.damage_handler.heal(target, hp)
        end
      end
    end
    Move.register(:s_life_dew, LifeDew)

    # Class describing a heal move
    class JungleHealing < HealMove
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          hp = target.max_hp / 4
          logic.damage_handler.heal(target, hp)
          next if target.status == 0 || target.dead?

          scene.logic.status_change_handler.status_change(:cure, target)
        end
      end
    end
    Move.register(:s_jungle_healing, JungleHealing)
  end
end
