module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler < Pokemon
    include Hooks
    # List of properties to copy
    COPIED_PROPERTIES = %i[
      @id @form @given_name @code @ability @nature
      @iv_hp @iv_atk @iv_dfe @iv_spd @iv_ats @iv_dfs
      @ev_hp @ev_atk @ev_dfe @ev_spd @ev_ats @ev_dfs
      @trainer_id @trainer_name @step_remaining @loyalty
      @exp @hp @status @status_count @item_holding
      @captured_with @captured_in @captured_at @captured_level
      @gender @skill_learnt @ribbons @character
      @exp_rate @hp_rate @egg_at @egg_in
    ]
    # List of properties to copy back to original
    BACK_PROPETIES = %i[
      @id @form @given_name @ability @level
      @ev_hp @ev_atk @ev_dfe @ev_spd @ev_ats @ev_dfs
      @trainer_id @trainer_name @step_remaining @loyalty
      @exp @hp @status @status_count @item_holding
      @captured_with @captured_in @captured_at @captured_level
      @gender @character @exp_rate @hp_rate
    ]

    # @return [Array<Battle::Move>] the moveset of the Pokemon
    attr_reader :moveset

    # @return [Integer] number of turn the Pokemon is in battle
    attr_accessor :turn_count
    alias battle_turns turn_count # BE24

    # Last turn the Pokemon fought
    # @return [Integer]
    attr_accessor :last_battle_turn

    # Last turn the pokemon was sent out
    # @return [Integer]
    attr_accessor :last_sent_turn

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

    # Get the move history
    # @return [Array<MoveHistory>]
    attr_reader :move_history

    # Get the information if the Pokemon is actually a follower or not (changing its go-in-out animation)
    # @return [Boolean]
    attr_accessor :is_follower

    # Get the bag of the battler
    # @return [PFM::Bag]
    attr_accessor :bag

    # Tell if the Pokemon already distributed its experience during the battle
    # @return [Boolean]
    attr_accessor :exp_distributed

    # Get the item held during battle
    # @return [Integer]
    attr_accessor :battle_item

    # Get the data associated to the item if needed
    # @return [Array]
    attr_reader :battle_item_data

    # @return [Boolean] set switching state
    attr_writer :switching

    # Mimic move that was replace by another move with its index
    # @return [Array<Battle::Move, Integer>]
    attr_accessor :mimic_move

    # Get the transform pokemon
    # @return [PFM::Pokemon]
    attr_reader :transform

    # Create a new PokemonBattler from a Pokemon
    # @param original [PFM::Pokemon] original Pokemon (protected during the battle)
    # @param scene [Battle::Scene] current battle scene
    # @param max_level [Integer] new max level for Online battle
    def initialize(original, scene, max_level = Float::INFINITY)
      @original = original
      # @type [PFM::Pokemon]
      @transform = nil
      @scene = scene
      scene.logic.transform_handler.initialize_transform_attempt(self)
      copy_properties
      copy_moveset
      @battle_stage = Array.new(7, 0)
      reset_states
      @battle_max_level = max_level
      @level = original.level < max_level ? original.level : max_level
      @type3 = 0
      @bank = 0
      @position = -1
      @order = -1
      @battle_item_data = []
      @battle_item = @item_holding
      @last_battle_turn = -1
      @last_sent_turn = -1
      @move_history = []
      @mega_evolved = false
      @exp_distributed = false
      initialize_set_is_follower
    end

    # Reload the original ability
    def reset_ability
      @ability = @original.ability
    end

    # Is the Pokemon able to fight ?
    # @return [Boolean]
    def can_fight?
      log_error("The pokemon #{self} has undefined position, it should be -1 if not in battle") unless @position
      return @position && @position >= 0 && !dead?
    end

    def to_s
      "<PB:#{name},#{@bank},#{@position} lv=#{@level} hp=#{@hp_rate.round(3)} st=#{@status}>"
    end
    alias inspect to_s

    def from_party?
      $actors.include?(@original)
    end

    # Return the db_symbol of the current ability of the Pokemon
    # @return [Symbol]
    def ability_db_symbol
      return GameData::Abilities.db_symbol(@ability_current || -1)
    end

    # Return the db_symbol of the current ability of the Pokemon for battle
    # @return [Symbol]
    def battle_ability_db_symbol
      return :__undef__ if @effects.has?(:ability_suppressed) && $scene.is_a?(Battle::Scene)

      return ability_db_symbol
    end

    # Tell if the pokemon has an ability
    # @param db_symbol [Symbol] db_symbol of the ability
    # @return [Boolean]
    def has_ability?(db_symbol)
      return battle_ability_db_symbol == db_symbol
    end

    # Return the db_symbol of the current item the Pokemon is holding
    # @return [Symbol]
    def item_db_symbol
      GameData::Item.db_symbol(@battle_item || -1)
    end

    # Get the item for battle
    # @return [Symbol]
    def battle_item_db_symbol
      return :__undef__ if battle_ability_db_symbol == :klutz

      return item_db_symbol
    end

    # Tell if the pokemon hold an item
    # @param db_symbol [Symbol] db_symbol of the item
    # @return [Boolean]
    def hold_item?(db_symbol)
      return battle_item_db_symbol == db_symbol
    end

    # Add a move to the move history
    # @note This method should only be used for sucessfull moves!!!
    # @param move [Battle::Move]
    # @param targets [Array<PFM::PokemonBattler>]
    def add_move_to_history(move, targets)
      @move_history << MoveHistory.new(move, targets, attack_order)
    end

    # Test if the last move was of a certain symbol
    # @param db_symbol [Symbol] symbol of the move
    def last_successfull_move_is?(db_symbol)
      return @move_history.last&.db_symbol == db_symbol
    end

    # Test if the Pokemon can use a move
    # @return [Boolean]
    def can_move?
      return false if moveset.all? { |move| move.pp == 0 || move.disabled?(self) }

      return true
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
      return test unless has_ability?(:mold_breaker) || has_ability?(:teravolt) || has_ability?(:turboblaze)

      unless ability_used
        @scene.visual.show_ability(self)

        self.ability_used = true
      end
      return false
    end

    # Let the Pokemon learn skill when leveling up
    # @param silent [Boolean] if the skill is automatically learnt or not (false = show skill learn interface & messages)
    # @param level [Integer] The level to check in order to learn the moves
    def check_skill_and_learn(silent = false, level = @level)
      copy_properties_back_to_original
      @original.check_skill_and_learn(silent, level)
      copy_moveset
    end

    # Copy all the properties back to the original pokemon
    def copy_properties_back_to_original
      return if @scene.battle_info.max_level

      original = @original
      BACK_PROPETIES.each do |ivar_name|
        original.instance_variable_set(ivar_name, instance_variable_get(ivar_name))
      end
      @moveset.each_with_index do |move, i|
        @original.skills_set[i]&.pp = move.pp
      end
    end

    # Function that resets everything from the pokemon once it got switched out of battle
    def reset_states
      @battle_stage.map! { 0 }
      @status_count = 0 if toxic?
      @effects = Battle::Effects::EffectsHandler.new
      @ability_current = @ability
      @switching = false
      @turn_count = 0
      if mimic_move
        @moveset[mimic_move.last] = mimic_move.first
        @moveset.compact!
        @mimic_move = nil
      end
    end

    # if the pokemon is switching during this turn
    # @return [Boolean]
    def switching?
      @switching
    end

    # Confuse the Pokemon
    # @param _ [Boolean] (ignored)
    # @return [Boolean] if the pokemon has been confused
    def status_confuse(_ = false)
      return false if dead? || confused?

      effects.add(Battle::Effects::Confusion.new(@scene.logic, self))
      return true
    end

    # Is the Pokemon confused?
    # @return [Boolean]
    def confused?
      return effects.has?(:confusion)
    end

    # Apply the flinch effect
    # @param forced [Boolean] this parameter is ignored since flinch effect is volatile
    def apply_flinch(forced = false)
      old_effect = @effects.get(:flinch)
      return if old_effect && !old_effect.dead?

      @effects.add(Battle::Effects::Flinch.new(@scene.logic, self))
    end

    # Transform this pokemon into another pokemon
    # @param pokemon [PFM::Pokemon, nil]
    def transform=(pokemon)
      @transform = pokemon
      return unless @moveset

      copy_properties
      copy_moveset
    end

    private

    # Copy the properties of the original pokemon
    def copy_properties
      original = @transform || @original
      COPIED_PROPERTIES.each do |ivar_name|
        instance_variable_set(ivar_name, original.instance_variable_get(ivar_name))
      end
    end

    # Copy the moveset of the original Pokemon
    def copy_moveset
      original = @transform || @original
      original = @original if @original.ability_db_symbol == :illusion && !effects&.has?(:transform)
      @skills_set = @moveset = original.skills_set.map do |skill|
        if original == @original
          next Battle::Move[skill.symbol].new(skill.id, skill.pp, skill.ppmax, @scene)
        else
          next Battle::Move[skill.symbol].new(skill.id, 5, 5, @scene)
        end
      end
      @moveset << Battle::Move.new(0, 0, 9001, @scene) if @moveset.empty?
    end

    # Function that sets the is_follower variable (for animation purpose)
    def initialize_set_is_follower
      return @is_follower = false unless $actors.include?(original) && defined?(Yuki::FollowMe)
      return @is_follower = false unless Yuki::FollowMe.enabled

      @is_follower = $actors.index(original).to_i < Yuki::FollowMe.pokemon_count
    end
  end
end
