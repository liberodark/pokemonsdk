module Battle
  class Move
    # Class managing ability changing moves
    class AbilityChanging < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? { |target| can_be_used?(user, target) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless can_be_used?(user, target)

          args = [receiver(user, target), ability_symbol(giver(user, target)), giver(user, target), self]
          @logic.ability_change_handler.apply_ability_change(*args) do
            post_ability_change_message(receiver(user, target), giver(user, target))
          end
        end
      end

      # Checks if the user can use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def can_be_used?(user, target)
        return false if user == target

        if is_a?(Battle::Move::SimpleBeam)
          # Ensure we compare the receiver's ability with Simple / Insomnia (because ability_symbol() is rewritten)
          return false if receiver(user, target).battle_ability_db_symbol == ability_symbol(giver(user, target))
          # We don't want to check the giver's ability in the handler, so we send nil.
          return false unless @logic.ability_change_handler.can_change_ability?(receiver(user, target), nil, self)

          return true
        end

        return false if ability_symbol(receiver(user, target)) == ability_symbol(giver(user, target))
        return false unless @logic.ability_change_handler.can_change_ability?(receiver(user, target), giver(user, target), self)

        return true
      end

      # Get the post ability change message
      # @param receiver [PFM::PokemonBattler] Ability receiver
      # @param giver [PFM::PokemonBattler] Potential ability giver
      # @return [String]
      # @note data_ability(ability_symbol(giver)).name to manage the Classic and Simple Beam cases
      def post_ability_change_message(receiver, giver)
        return parse_text_with_pokemon(19, 405, receiver, PFM::Text::ABILITY[1] => data_ability(ability_symbol(giver)).name)
      end

      # Function that returns the battle ability of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Symbol]
      def ability_symbol(battler)
        return battler.battle_ability_db_symbol
      end

      # Function that returns the receiver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def receiver(user, target)
        raise 'This method should be implemented in the subclass'
      end

      # Function that returns the giver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def giver(user, target)
        raise 'This method should be implemented in the subclass'
      end
    end

    # Class managing Entrainment move
    class Entrainment < AbilityChanging
      # Function that returns the receiver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def receiver(_, target)
        return target
      end

      # Function that returns the giver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def giver(user, _)
        return user
      end
    end

    # Class managing Simple Beam move
    class SimpleBeam < Entrainment
      # Function that returns the battle ability of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Symbol]
      def ability_symbol(_)
        return :simple
      end
    end

    # Class managing Worry Seed move
    class WorrySeed < SimpleBeam
      # Function that returns the battle ability of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Symbol]
      def ability_symbol(_)
        return :insomnia
      end
    end

    # Class managing Role Play move
    class RolePlay < AbilityChanging
      # Function that returns the receiver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def receiver(user, _)
        return user
      end

      # Function that returns the giver of the ability
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [PFM::PokemonBattler]
      def giver(_, target)
        return target
      end
    end

    # Class managing Doodle move
    class Doodle < RolePlay
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.all? do |target|
          @logic.alive_battlers(user.bank).none? do |battler|
            can_be_used?(battler, target)
          end
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          @logic.alive_battlers(user.bank).each do |battler|
            next unless can_be_used?(battler, target)

            args = [receiver(battler, target), ability_symbol(giver(battler, target)), giver(battler, target), self]
            @logic.ability_change_handler.apply_ability_change(*args) do
              post_ability_change_message(receiver(battler, target), giver(battler, target))
            end
          end
        end
      end
    end

    # Class managing Skill Swap move
    class SkillSwap < AbilityChanging
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless can_be_used?(user, target)

          @logic.ability_change_handler.apply_ability_swap(user, target, self)
        end
      end

      # Checks if the user can use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def can_be_used?(user, target)
        return false if user == target
        return false if ability_symbol(user) == ability_symbol(target)
        return false unless @logic.ability_change_handler.can_change_ability?(target, user, self)
        return false unless @logic.ability_change_handler.can_change_ability?(user, target, self)

        return true
      end
    end

    Move.register(:s_entrainment, Entrainment)
    Move.register(:s_simple_beam, SimpleBeam)
    Move.register(:s_worry_seed, WorrySeed)
    Move.register(:s_role_play, RolePlay)
    Move.register(:s_doodle, Doodle)
    Move.register(:s_skill_swap, SkillSwap)
  end
end
