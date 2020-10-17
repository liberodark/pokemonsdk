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
      @gender @skill_learnt @ribbons
      @exp_rate @hp_rate @egg_at @egg_in
    ]

    # @return [Array<Battle::Move>] the moveset of the Pokemon
    attr_reader :moveset

    # @return [Symbol, nil] the last successfull move (during the previous turn)
    attr_accessor :last_successfull_move

    # @return [Integer] number of turn the Pokemon is in battle
    attr_accessor :turn_count
    alias battle_turns turn_count # BE24

    # Last turn the Pokemon fought
    # @return [Integer]
    attr_accessor :last_battle_turn

    # @return [Battle::Move] last move that hit the pokemon
    attr_accessor :last_hit_by_move

    # @return [Integer] 3rd type (Mega / Move effect)
    attr_accessor :type3

    # @return [Integer] the ID of the party that control the Pokemon in the bank
    attr_accessor :party_id

    # @return [Integer] Bank where the Pokemon is supposed to be
    attr_accessor :bank

    # @return [Integer] Position of the Pokemon in the bank
    attr_accessor :position

    # @return [Numeric] Order of the Pokemon in the action chain (the lesser the faster)
    attr_accessor :order

    # Get the original Pokemon
    # @return [PFM::Pokemon]
    attr_reader :original

    # Get the effect hanndler
    # @return [Battle::Effects::EffectsHandler]
    attr_reader :effects

    # Create a new PokemonBattler from a Pokemon
    # @param original [PFM::Pokemon] original Pokemon (protected during the battle)
    # @param scene [Battle::Scene] current battle scene
    # @param max_level [Integer] new max level for Online battle
    def initialize(original, scene, max_level = Float::INFINITY)
      @original = original
      @scene = scene
      copy_properties
      copy_moveset
      init_states
      @level = original.level < max_level ? original.level : max_level
      @type3 = 0
      @bank = 0
      @position = -1
      @order = -1
      @battle_item_data = []
      @battle_item = @item_holding
      @last_battle_turn = -1
      @effects = Battle::Effects::EffectsHandler.new
    end

    # Reload the original ability
    def reset_ability
      @ability = @original.ability
    end

    # Is the Pokemon able to fight ?
    # @return [Boolean]
    def can_fight?
      @position && !dead?
    end

    # Is the pokemon able to use a move ?
    # @return [Boolean]
    def can_use_move?
      moves = @moveset
      # TODO : Implement all the move conditions
      return moves.any? { |move| move.pp > 0 }
    end

    def to_s
      "<PB:#{name},#{@bank},#{@position} lv=#{@level} hp=#{@hp_rate.round(3)} st=#{@status}>"
    end
    alias inspect to_s

    def from_party?
      $actors.include?(@original)
    end

    # Test if the Pokemon can have a lowering stat or have its move canceled (return false if the Pokemon has mold breaker)
    #
    # List of ability that should be affected:
    # :battle_armor|:clear_body|:damp|:dry_skin|:filter|:flash_fire|:flower_gift|:heatproof|:hyper_cutter|:immunity|:inner_focus|:insomnia|
    # :keen_eye|:leaf_guard|:levitate|:lightning_rod|:limber|:magma_armor|:marvel_scale|:motor_drive|:oblivious|:own_tempo|:sand_veil|:shell_armor|
    # :shield_dust|:simple|:snow_cloak|:solid_rock|:soundproof|:sticky_hold|:storm_drain|:sturdy|:suction_cups|:tangled_feet|:thick_fat|:unaware|:vital_spirit|
    # :volt_absorb|:water_absorb|:water_veil|:white_smoke|:wonder_guard|:big_pecks|:contrary|:friend_guard|:heavy_metal|:light_metal|:magic_bounce|:multiscale|
    # :sap_sipper|:telepathy|:wonder_skin|:aroma_veil|:bulletproof|:flower_veil|:fur_coat|:overcoat|:sweet_veil|:dazzling|:disguise|:fluffy|:queenly_majesty|
    # :water_bubble|:mirror_armor|:punk_rock|:ice_scales|:ice_face|:pastel_veil
    # @param test [Boolean] if the test should be done
    # @return [Boolean] potential changed result
    def can_be_lowered_or_canceled?(test = true)
      return false unless test
      return test if ability_db_symbol != :mold_breaker

      unless ability_used
        @scene.visual.show_ability(self)

        self.ability_used = true
      end
      return false
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
        @moveset[index] = Battle::Move[skill.symbol].new(skill.id, skill.pp, skill.ppmax, @scene)
      end
      @skills_set = @moveset
    end
  end
end
