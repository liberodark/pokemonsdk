module Battle
  class Move
    # Class describing a Pledge move (moves combining for different effects)
    class Pledge < Basic
      # List the db_symbol for every Pledge moves
      # @return [Array<Symbol>]
      PLEDGE_MOVES = %i[water_pledge fire_pledge grass_pledge]

      # Return the combination for each effect triggered by Pledge combination
      # @return [Hash { Symbol => Array<Symbol, Array<>> }
      COMBINATION_LIST = {
        rainbow: %i[water_pledge fire_pledge],
        sea_of_fire: %i[fire_pledge grass_pledge],
        swamp: %i[grass_pledge water_pledge]
      }

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return check_order_of_attack(user, targets) if scene.logic.battle_info.vs_type > 1 && scene.logic.alive_battlers(user.bank).size >= 2

        return true
      end

      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return @combined_pledge ? 160 : super
      end

      # Function which permit things to happen before the move's animation
      def post_accuracy_check_move(user, actual_targets)
        scene.display_message_and_wait(parse_text(18, 193)) if @combined_pledge
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return false unless @combined_pledge

        comb_arr = [db_symbol, @combined_pledge]
        effect_symbol = nil
        COMBINATION_LIST.each { |key, value| effect_symbol = key if comb_arr & value == comb_arr }
        return unless effect_symbol

        send(effect_symbol, user, actual_targets)
        @combined_pledge = nil
        return true
      end

      # Register a Pledge move as one in the System
      # @param db_symbol [Symbol] db_symbol of the move
      def register_pledge_move(db_symbol)
        PLEDGE_MOVES << db_symbol unless PLEDGE_MOVES.include?(db_symbol)
      end

      # Register a pledge combination
      # @param effect_symbol [Symbol]
      # @param first_pledge_symbol [Symbol]
      # @param second_pledge_symbol
      def register_pledge_combination(effect_symbol, first_pledge_symbol, second_pledge_symbol)
        COMBINATION_LIST[effect_symbol] = [first_pledge_symbol, second_pledge_symbol]
      end

      private

      # Check the order to know if the user uses its Pledge Move or wait for the other to attack
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean]
      def check_order_of_attack(user, targets)
        allied_actions = scene.logic.turn_actions.select { |action| action.is_a?(Actions::Attack) && Actions::Attack.from(action).launcher.bank == user.bank }
        return true if allied_actions.size <= 1 || !allied_actions.all? { |action| PLEDGE_MOVES.include?(action.move.db_symbol) }

        # @type [Actions::Attack]
        other_move = (allied_actions.find { |action| action.launcher != user })
        # @type [PFM::PokemonBattler]
        other = other_move.launcher
        if user.attack_order < other.attack_order
          scene.display_message_and_wait(pledge_wait_text(user, other))
          user.add_successful_move_to_history(self, targets)
          return false
        else
          @combined_pledge = other_move.move.db_symbol
          return true
        end
      end

      # Get the right text depending on the user's side (and if it's a Trainer battle or not)
      # @param user [PFM::PokemonBattler]
      # @param other [PFM::PokemonBattler]
      # @return [String]
      def pledge_wait_text(user, other)
        text_id = (user.bank == 0 ? 1152 : (scene.logic.battle_info.trainer_battle? ? 1156 : 1158))
        parse_text(19, text_id, '[VAR PKNICK(0000)]' => user.given_name, '[VAR PKNICK(0001)]' => other.given_name)
      end

      # Create the Rainbow Effect
      # @param user [PFM::PokemonBattler]
      # @param _actual_targets [Array<PFM::PokemonBattler>]
      def rainbow(user, _actual_targets)
        return if logic.bank_effects[user.bank].has?(:rainbow)

        scene.logic.add_bank_effect(Battle::Effects::Rainbow.new(logic, user.bank))
      end

      # Create the SeaOfFire Effect
      # @param _user [PFM::PokemonBattler]
      # @param actual_targets [Array<PFM::PokemonBattler>]
      def sea_of_fire(_user, actual_targets)
        return if logic.bank_effects[actual_targets&.first&.bank].has?(:sea_of_fire)

        scene.logic.add_bank_effect(Battle::Effects::SeaOfFire.new(logic, actual_targets&.first&.bank))
      end

      # Create the Swamp Effect
      # @param _user [PFM::PokemonBattler]
      # @param actual_targets [Array<PFM::PokemonBattler>]
      def swamp(_user, actual_targets)
        return if logic.bank_effects[actual_targets&.first&.bank].has?(:swamp)

        scene.logic.add_bank_effect(Battle::Effects::Swamp.new(logic, actual_targets&.first&.bank))
      end
    end
    Move.register(:s_pledge, Pledge)
  end
end
