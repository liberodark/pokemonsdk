module Battle
  module Effects
    # Implement the Protect effect
    class Protect < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param move [Battle::Move] move that applied this effect
      def initialize(logic, pokemon, move)
        super(logic, pokemon)
        @move = move
        self.counter = 1
      end

      # Function called when we try to check if the target evades the move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @return [Boolean] if the target is evading the move
      def on_move_prevention_target(user, target, move)
        return false if goes_through_protect?(user, target, move)

        play_protect_effect(user, target, move)
        return true
      end

      # Function called when we try to check if the move goes through protect
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @return [Boolean] if the move goes through protect
      def goes_through_protect?(user, target, move)
        return true if target != @pokemon
        return true unless move.blocked_by?(target, @move.db_symbol)
        return true if user.has_ability?(:unseen_fist) && move.direct?

        return false
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :protect
      end

      # Handle the mirror armor effect (special case)
      # @param user [PFM::PokemonBattler, nil] Potential launcher of a move
      # @return [PFM::PokemonBattler, nil]
      def handle_mirror_armor_effect(user, target)
        return user.has_ability?(:mirror_armor) ? target : nil
      end

      private

      # Function responsive of playing the protect effect if protect got triggered (inc. message)
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      def play_protect_effect(user, target, move)
        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
      end

      @effect_classes = {}

      class << self
        # Register a Protect effect
        # @param db_symbol [Symbol] db_symbol of the move
        # @param klass [Class<Protect>] protect class
        def register(db_symbol, klass)
          @effect_classes[db_symbol] = klass
        end

        # Create a new effect
        # @param logic [Battle::Logic]
        # @param pokemon [PFM::PokemonBattler]
        # @param move [Battle::Move] move that applied this effect
        # @return [Protect]
        def new(logic, pokemon, move)
          klass = @effect_classes[move.db_symbol] || Protect
          object = klass.allocate
          object.send(:initialize, logic, pokemon, move)
          return object
        end
      end

      # Implement the Spiky Shield effect
      class SpikyShield < Protect
        private

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          hp = (user.hp / 8).clamp(1, Float::INFINITY)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
          move.logic.damage_handler.damage_change(hp, user) if move.made_contact?
        end
      end
      Protect.register(:spiky_shield, SpikyShield)

      # Implement the King's Shield effect
      class KingsShield < Protect
        # Function called when we try to check if the move goes through protect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the move goes through protect
        def goes_through_protect?(user, target, move)
          return true if move.status?

          return super
        end

        private

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))

          if move.made_contact?
            return move.scene.logic.stat_change_handler.stat_change_with_process(:atk, -1, user, handle_mirror_armor_effect(user, target))
          end
        end
      end
      Protect.register(:king_s_shield, KingsShield)

      # Implement the Silk Trap effect
      class SilkTrap < Protect
        # Function called when we try to check if the move goes through protect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the move goes through protect
        def goes_through_protect?(user, target, move)
          return true if move.status?

          return super
        end

        private

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
          if move.made_contact?
            move.scene.logic.stat_change_handler.stat_change_with_process(:spd, -1, user, handle_mirror_armor_effect(user, target))
          end
        end
      end
      Protect.register(:silk_trap, SilkTrap)

      # Implement the Obstruct effect
      class Obstruct < SilkTrap
        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false if goes_through_protect?(user, target, move)
          return false unless move&.direct? && !user.has_ability?(:long_reach)
          return false if user.hold_item?(:punching_glove) && move&.punching?
          return false unless immune?(user, target, move)

          play_protect_effect(user, target, move)

          return true
        end

        private

        # Function called when we try to check if the Pokemon is immune to a move's types
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to a move's types
        def immune?(user, target, move)
          move_types = move.definitive_types(user, target)

          target_types = []
          target_types << target.type1 << target.type2 << target.type3

          result = move_types.any? do |move_type|
            target_types.any? do |target_type|
              data_type(move_type).hit(data_type(target_type).db_symbol) == 0
            end
          end

          return result
        end

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
          return unless move.made_contact?

          move.scene.logic.stat_change_handler.stat_change_with_process(:dfe, -2, user, handle_mirror_armor_effect(user, target))
        end
      end
      Protect.register(:obstruct, Obstruct)

      # Implement the Baneful Bunker effect
      class BanefulBunker < Protect
        private

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
          handler = @logic.status_change_handler
          handler.status_change(:poison, user, message_overwrite: 234) if move.made_contact? && handler.status_appliable?(:poison, user)
        end
      end
      Protect.register(:baneful_bunker, BanefulBunker)

      # Implement the Burning Bulwark effect
      class BurningBulwark < Protect
        # Function called when we try to check if the move goes through protect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the move goes through protect
        def goes_through_protect?(user, target, move)
          return true if move.status?

          return super
        end

        private

        # Function responsive of playing the protect effect if protect got triggered (inc. message)
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        def play_protect_effect(user, target, move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
          handler = @logic.status_change_handler
          handler.status_change(:burn, user, message_overwrite: 255) if move.made_contact? && handler.status_appliable?(:burn, user)
        end
      end
      Protect.register(:burning_bulwark, BurningBulwark)

      # Implement the Mat Block effect
      class MatBlock < Protect
        # Function that tests if the user is able to use the move
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
        # @return [Boolean] if the procedure can continue
        def move_usable_by_user(user, targets)
          return unless super
          return show_usage_failure(user) && false if user.turn_count > 1 || user.effects.has?(:instruct)

          return true
        end

        # Function called when we try to check if the move goes through protect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the move goes through protect
        def goes_through_protect?(user, target, move)
          return true if move.status?

          return super
        end
      end
      Protect.register(:mat_block, MatBlock)

      # Implement the Mat Block effect
      class Endure < PokemonTiedEffectBase
        # Create a new Pokemon tied effect
        # @param logic [Battle::Logic]
        # @param pokemon [PFM::PokemonBattler]
        # @param move [Battle::Move] move that applied this effect
        def initialize(logic, pokemon, move)
          super(logic, pokemon)
          @move = move
          @show_message = false
          self.counter = 1
        end

        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @pokemon
          return if hp < target.hp
          return unless launcher && skill

          @show_message = true
          return target.hp - 1
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return unless @show_message

          @show_message = false
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 514, target))
        end
      end
      Protect.register(:endure, Endure)

      # Implement the Quick Guard effect
      class QuickGuard < Protect
        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return false if @pokemon.bank != target.bank
          return false if move.relative_priority <= 0

          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 800, target))
          return true
        end
      end
      Protect.register(:quick_guard, QuickGuard)

      # Implement the Wide Guard effect
      class WideGuard < Protect
        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return false if @pokemon.bank != target.bank
          return false if move.is_one_target?

          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 797, target))
          return true
        end
      end
      Protect.register(:wide_guard, WideGuard)
    end
  end
end
