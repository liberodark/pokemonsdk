module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler < Pokemon
    # List of properties to copy
    COPIED_PROPERTIES = %i[
      @id @form @given_name @code @ability @nature
      @iv_hp @iv_atk @iv_dfe @iv_spd @iv_ats @iv_dfs
      @ev_hp @ev_atk @ev_dfe @ev_spd @ev_ats @ev_dfs
      @trainer_id @trainer_name @step_remaining @loyalty
      @exp @hp @status @status_count @item_holding
      @captured_with @captured_in @captured_at @captured_level
      @shiny @gender @skill_learnt @ribbons
      @exp_rate @hp_rate
    ]

    # @return [Array<Battle::Move>] the moveset of the Pokemon
    attr_reader :moveset

    # Create a new PokemonBattler from a Pokemon
    # @param original [PFM::Pokemon] original Pokemon (protected during the battle)
    # @param max_level [Integer] new max level for Online battle
    def initialize(original, max_level = GameData::MAX_LEVEL)
      @original = original
      copy_properties
      copy_moveset
      init_states
    end

    # Reload the original ability
    def reset_ability
      @ability = @original.ability
    end

    private

    # Copy the properties of the original pokemon
    def copy_properties
      original = @original
      COPIED_PROPERTIES.each do |ivar_name|
        instance_variable_set(ivar_name, original.instance_variable_get(ivar_name))
      end
    end

    # Copy the moveset of the original Pokemon
    def copy_moveset
      @moveset = Array.new(@original.skills_set.size)
      @original.skills_set.each_with_index do |skill, index|
        @moveset[index] = Battle::Move[skill.symbol].new(skill.id, skill.pp, skill.ppmax)
      end
      @skills_set = @moveset
    end
  end
end
