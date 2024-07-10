module Battle
  class Move
    class AuraWheel < SelfStat
      # Hash containing each valid user and the move's type depending on the form
      # @return [Hash{Symbol => Hash}]
      VALID_USER = Hash.new

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false unless VALID_USER[user.db_symbol]

        return true
      end

      # Get the types of the move with 1st type being affected by effects
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Array<Integer>] list of types of the move
      def definitive_types(user, target)
        return [data_type(VALID_USER[user.db_symbol][user.form]).id]
      end

      class << self
        # Register a valid user for this move
        # @param creature_db_symbol [Symbol] db_symbol of the new valid user
        # @param forms_and_types [Array<Array>] the array containing the informations
        # @param default [Symbol] db_symbol of the type by default for this user
        # @example : register_valid_user(:pikachu, [0, :electrik], [1, :psychic], [2, :fire], default: :electrik)
        # This will let Pikachu use the move, its form 0 will make the move Electrik type, form 1 Psychic type, its form 2 Fire type
        # and any other form will have Electrik type by default
        def register_valid_user(creature_db_symbol, *forms_and_types, default: nil)
          VALID_USER[creature_db_symbol] = forms_and_types.to_h
          VALID_USER[creature_db_symbol].default = default || forms_and_types.to_h.first[1]
        end
      end

      register_valid_user(:morpeko, [0, :electric], [1, :dark], default: :electrik)
    end
    Move.register(:s_aura_wheel, AuraWheel)
  end
end
