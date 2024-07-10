module Battle
  module Effects
    class Ability
      class ParentalBond < Ability
        # Constant telling the be_method of the moves not affected by Parental Bond
        # @return [Array<Symbol>]
        ONLY_ONE_ATTACK = %i[s_solar_beam s_2turns s_endeavor s_ohko s_fling s_explosion s_final_gambit s_uproar
          s_rollout s_ice_ball s_relic_sound s_electro_shot
        ]
        # Constant telling which be_method can activate their effect on the second attack only
        # @return [Array<Symbol>]
        ONLY_ON_SECOND_ATTACK = %i[s_secret_power s_u_turn s_thief s_pluck s_smelling_salt s_wakeup_slap s_knock_off
          s_scald s_smack_down s_burn_up s_bind s_fury_cutter s_split_up s_reload s_outrage s_present s_pledge
        ]

        # If the talent is activated or not
        # @return [Boolean]
        attr_writer :activated
        # Returns the amount of damage the launcher must take from the recoil
        # @return [Integer]
        attr_accessor :first_turn_recoil
        # Which attack number are we currently on this turn?
        # @return [Integer]
        attr_accessor :attack_number

        # Create a new Parental Bond effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
          @first_turn_recoil = 0
          @attack_number = 0
        end

        def activated?
          return @activated
        end
        alias activated activated?

        # Return the specific proceed_internal if the condition is fulfilled
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        def specific_proceed_internal(user, targets, move)
          return :proceed_internal_parental_bond unless excluded?(move.be_method)
        end

        # Get the name of the effect
        # @return [Symbol]
        def name
          return :parental_bond
        end

        # Returns the number of attack this Ability causes
        # @return [Integer]
        def number_of_attacks
          return 2
        end

        # Check if the actual move can activate its have his effect activated
        # @return [Boolean]
        def first_effect_can_be_applied?(be_method)
          return ONLY_ON_SECOND_ATTACK.none?(be_method)
        end

        # Check if the actual move need the initial procedure (Parental Bond not working on it)
        # @return [Boolean]
        def excluded?(be_method)
          return ONLY_ONE_ATTACK.any?(be_method)
        end

        # Give the move mod3 mutiplier (after everything)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def mod3_multiplier(user, target, move)
          return 0.50 if activated?

          return 1
        end
      end
      register(:parental_bond, ParentalBond)
    end
  end
end
