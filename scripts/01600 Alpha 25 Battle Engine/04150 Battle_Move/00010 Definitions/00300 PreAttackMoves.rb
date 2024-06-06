module Battle
  class Move
    class PreAttackBase < Basic
      # Is the move doing something before any other moves ?
      # @return [Boolean]
      def pre_attack?
        return true
      end

      # Proceed the procedure before any other attack.
      # @param user [PFM::PokemonBattler]
      def proceed_pre_attack(user)
        return unless can_pre_use_move?(user)

        pre_attack_effect(user)
        pre_attack_message(user)
        pre_attack_animation(user)
      end

      # Check if the user is able to display the message related to the move
      # @param user [PFM::PokemonBattler] user of the move
      def can_pre_use_move?(user)
        @enabled = false
        return false if user.frozen? || user.asleep?

        @enabled = true
        return true
      end

      # Class of the Effect given by this move
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_effect(user)
        return nil
      end

      # Display the charging message
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_message(user)
        return nil
      end

      # Display the charging animation
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_animation(user)
        return nil
      end

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? { |target| move_usable?(user, target) }

        return true
      end

      # Tell if the move is usable
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def move_usable?(user, target)
        return false unless @enabled

        return true
      end

      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return true if super
        return true unless move_usable?(user, target)

        return false
      end
    end

    # Implement the Focus Punch move
    class FocusPunch < PreAttackBase
      # Display the charging message
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_message(user)
        return @scene.display_message_and_wait(parse_text_with_pokemon(19, 616, user))
      end

      # Tell if the move is usable
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def move_usable?(user, target)
        return false unless super
        return false if disturbed?(user)

        return true
      end

      # Is the pokemon unable to proceed the attack ?
      # @param user [PFM::PokemonBattler]
      # @return [Boolean]
      def disturbed?(user)
        return user.damage_history.any?(&:current_turn?)
      end
    end

    # Implement the Beak Blast move
    class BeakBlast < PreAttackBase
      # Class of the Effect given by this move
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_effect(user)
        return user.effects.add(Effects::BeakBlast.new(@logic, user))
      end

      # Display the charging message
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_message(user)
        return @scene.display_message_and_wait(parse_text_with_pokemon(59, 1880, user))
      end
    end

    # Implement the Shell Trap move
    class ShellTrap < PreAttackBase
      # Class of the Effect given by this move
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_effect(user)
        return user.effects.add(Effects::ShellTrap.new(logic, user))
      end

      # Display the charging message
      # @param user [PFM::PokemonBattler] user of the move
      def pre_attack_message(user)
        return @scene.display_message_and_wait(parse_text_with_pokemon(59, 1884, user))
      end

      # Tell if the move is usable
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def move_usable?(user, target)
        return false unless super
        return false if user.effects.has?(:shell_trap)

        return true
      end

      # Show the usage failure when move is not usable by user
      # @param user [PFM::PokemonBattler] user of the move
      def show_usage_failure(user)
        return scene.display_message_and_wait(parse_text_with_pokemon(59, 1888, user))
      end
    end

    Move.register(:s_focus_punch, FocusPunch)
    Move.register(:s_beak_blast, BeakBlast)
    Move.register(:s_shell_trap, ShellTrap)
    Move.register(:s_pre_attack_base, PreAttackBase)
  end
end
