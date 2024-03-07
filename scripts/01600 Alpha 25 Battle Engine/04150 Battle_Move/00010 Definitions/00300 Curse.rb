module Battle
  class Move
    # Class managing Curse
    class Curse < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return true unless user.type_ghost?

        return show_usage_failure(user) && false if targets.all? { |target| target.effects.has?(:curse) }

        return true
      end


      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return false unless user.type_ghost?
        return true if super

        return scene.display_message_and_wait(parse_text_with_pokemon(19, 213, target)) && true if target.effects.has?(:curse)

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.type_ghost? ? apply_ghost_type_effects(user, actual_targets) : apply_non_ghost_type_effects(user)
      end

      private

      # Function to apply effects for Ghost-type Pokémon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def apply_ghost_type_effects(user, actual_targets)
        hp = (user.max_hp / 2).clamp(1, user.hp)

        logic.damage_handler.damage_change(hp, user, user, self)
        actual_targets.each do |target|
          target.effects.add(Effects::Curse.new(logic, target))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1070, target, PFM::Text::PKNICK[0] => user.given_name, PFM::Text::PKNICK[1] => target.given_name))
        end
      end

      # Function to apply effects for non-Ghost-type Pokémon
      # @param user [PFM::PokemonBattler] user of the move
      def apply_non_ghost_type_effects(user)
        logic.stat_change_handler.stat_change_with_process(:spd, -1, user, user, self)
        logic.stat_change_handler.stat_change_with_process(:atk, 1, user, user, self)
        logic.stat_change_handler.stat_change_with_process(:dfe, 1, user, user, self)
      end
    end

    Move.register(:s_curse, Curse)
  end
end
