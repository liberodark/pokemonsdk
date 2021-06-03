module Battle
  class Move
    # Range of the R random factor
    R_RANGE = 85..100

    # Method calculating the damages done by the actual move
    # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def damages(user, target)
      log_data("# damages(#{user}, #{target}) for #{db_symbol}")
      log_data("# user_item_multiplier reason : #{user.battle_item_db_symbol}")
      log_data("# foe_item_multiplier reason : #{target.battle_item_db_symbol}")
      log_data("# user_ability_multiplier reason : #{user.battle_ability_db_symbol}")
      log_data("# foe_ability_multiplier reason : #{target.battle_ability_db_symbol}")
      @critical = logic.calc_critical_hit(user, target, critical_rate)
      log_data("@critical = #{@critical} # critical_rate = #{critical_rate}")
      # Reset the effectiveness
      @effectiveness = 1
      # (((((((Level * 2 / 5) + 2) * BasePower * [Sp]Atk / 50) / [Sp]Def) * Mod1) + 2) *
      # CH * Mod2 * R / 100) * STAB * Type1 * Type2 * Mod3)
      damage = user.level * 2 / 5 + 2
      log_data("damage = #{damage} # #{user.level} * 2 / 5 + 2")
      damage = (damage * calc_base_power(user, target)).floor
      log_data("damage = #{damage} # after calc_base_power")
      damage = (damage * calc_sp_atk(user, target)).floor
      damage /= 50
      log_data("damage = #{damage} # after calc_sp_atk / 50")
      damage = (damage / calc_sp_def(user, target)).floor
      log_data("damage = #{damage} # after calc_sp_def")
      damage = (damage * calc_mod1(user, target)).floor
      log_data("damage = #{damage} # after calc_mod1")
      damage += 2
      damage = (damage * calc_ch(user)).floor
      damage = (damage * calc_mod2(user, target)).floor
      log_data("damage = #{damage} # after calc_mod2 & calc_ch")
      damage *= logic.move_damage_rng.rand(calc_r_range)
      damage /= 100
      log_data("damage = #{damage} # after rng")
      damage = (damage * calc_stab(user)).floor
      log_data("damage = #{damage} # after stab")
      types = definitive_types(user, target)
      log_data("types = #{types} # ie: #{types.map do |t| GameData::Type[t].name end.join(', ')}")
      damage = (damage * calc_type_n_multiplier(target, :type1, types)).floor
      log_data("damage = #{damage} # after type1 (#{GameData::Type[target.type1].name}) => new_eff = #{@effectiveness}")
      damage = (damage * calc_type_n_multiplier(target, :type2, types)).floor
      log_data("damage = #{damage} # after type2 (#{GameData::Type[target.type2].name}) => new_eff = #{@effectiveness}")
      damage = (damage * calc_type_n_multiplier(target, :type3, types)).floor
      log_data("damage = #{damage} # after type3 (#{GameData::Type[target.type3].name}) => new_eff = #{@effectiveness}")
      log_data("damage = #{(damage * calc_mod3(user, target)).floor} # after mod3") if debug?
      damage = (damage * calc_mod3(user, target)).floor
      return damage
    end

    # Function that calculate the type modifier (for specific uses)
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def type_modifier(user, target)
      types = definitive_types(user, target)
      n = calc_type_n_multiplier(target, :type1, types) *
          calc_type_n_multiplier(target, :type2, types) *
          calc_type_n_multiplier(target, :type3, types)
      return n
    end

    # STAB calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @return [Numeric]
    def calc_stab(user)
      if user.type1 == type || user.type2 == type || user.type3 == type
        return 2 if user.has_ability?(:adaptability)

        return 1.5
      end
      return 1
    end

    # Get the real base power of the move (taking in account all parameter)
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def real_base_power(user, target)
      return power
    end

    private

    # Base power calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def calc_base_power(user, target)
      # HH * BP * IT * CHG * MS * WS * UA * FA
      # BP
      result = real_base_power(user, target)
      # Effects
      logic.each_effects(user, target) do |e|
        result = (result * e.base_power_multiplier(user, target, self)).floor
      end
      result = result.floor # Round down between each multiplication, the first two can be reverted.
      # IT
      result = (result * send(ITEM_MULTIPLIER[user.battle_item_db_symbol], user, target)).floor
      # CHG
      result = user.effects.has?(:charge) ? user.effects.get(:charge).calc_base_power_as_user(result, user, target, self) : result
      # MS
      result = (result * VAL_0_5).floor if logic.terrain_effects.has?(:mud_sport) && type == GameData::Types::ELECTRIC
      # WS
      result = (result * VAL_0_5).floor if logic.terrain_effects.has?(:water_sport) && type == GameData::Types::FIRE
      # UA
      result = (result * send(USER_ABILITY_MULTIPLIER[user.battle_ability_db_symbol], user, target)).floor
      # FA
      return (result * send(FOE_ABILITY_MULTIPLIER[target.battle_ability_db_symbol], user, target)).floor
    end

    # [Spe]atk calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def calc_sp_atk(user, target)
      # [Sp]Atk = Stat * SM * AM * IM
      ph_move = physical?
      # Stat
      result = calc_sp_atk_basis(user, target, ph_move)
      # SM (Only if non-critical hit)
      result = (result * calc_atk_stat_modifier(user, target, ph_move)).floor
      # Effects
      logic.each_effects(user, target) do |e|
        result = (result * e.sp_atk_multiplier(user, target, self)).floor
      end
      # Flower Gift
      result = (result * flower_gift_atk_calc(user, ph_move)).floor
      # AM
      am = send((ph_move ? ATK_ABILITY_MODIFIER : ATS_ABILITY_MODIFIER)[user.battle_ability_db_symbol], user, target)
      result = (result * am).floor
      # IM
      return (result * send((ph_move ? ATK_ITEM_MODIFIER : ATS_ITEM_MODIFIER)[user.battle_item_db_symbol], user, target)).floor
    end

    # Get the basis atk for the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @param ph_move [Boolean] true: physical, false: special
    # @return [Integer]
    def calc_sp_atk_basis(user, target, ph_move)
      return ph_move ? user.atk_basis : user.ats_basis
    end

    UNAWARE_IGNORING_ABILITIES = %i[turboblaze teravolt mold_breaker]
    # Statistic modifier calculation: ATK/ATS
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @param ph_move [Boolean] true: physical, false: special
    # @return [Integer]
    def calc_atk_stat_modifier(user, target, ph_move)
      return 1 if critical_hit?
      return 1 if target.has_ability?(:unaware) && !UNAWARE_IGNORING_ABILITIES.include?(user.battle_ability_db_symbol)

      return ph_move ? user.atk_modifier : user.ats_modifier
    end

    # Flower Gift calculation: ATK/ATS
    # @param user [PFM::PokemonBattler] user of the move
    # @param ph_move [Boolean] true: physical, false: special
    # @return [Integer]
    def flower_gift_atk_calc(user, ph_move)
      return 1 unless ph_move && $env.sunny?
      return 1 unless logic.allies_of(user).any? { |ally| ally.has_ability?(:flower_gift) } || user.has_ability?(:flower_gift)

      return 1.5
    end

    EXPLOSION_SELF_DESTRUCT_MOVE = %i[explosion self-destruct]
    # [Spe]def calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def calc_sp_def(user, target)
      # [Sp]Def = Stat * SM * Mod * SX
      ph_move = physical?
      # Stat
      result = ph_move ? target.dfe_basis : target.dfs_basis
      # SM (Only if non-critical hit)
      unless user.has_ability?(:unaware) || critical_hit?
        result = (result * (ph_move ? target.dfe_modifier : target.dfs_modifier)).floor
      end
      # Effects
      logic.each_effects(user, target) do |e|
        result = (result * e.sp_def_multiplier(user, target, self)).floor
      end
      # Flower Gift & Sandstorm
      result = (result * flower_gift_dfe_calc(target, ph_move) * sandstorm_calc(target, ph_move)).floor
      # Mod
      mod = send((ph_move ? DFE_ABILITY_MODIFIER : DFS_ABILITY_MODIFIER)[target.battle_ability_db_symbol], user, target)
      result = (result * mod).floor
      mod = send((ph_move ? DFE_ITEM_MODIFIER : DFS_ITEM_MODIFIER)[target.battle_item_db_symbol], user, target)
      result = (result * mod).floor
      # SX
      result = (result * VAL_0_5).floor if EXPLOSION_SELF_DESTRUCT_MOVE.include?(db_symbol)
      return result
    end

    # Flower Gift calculation: DFE/DFS
    # @param target [PFM::PokemonBattler] target of the move
    # @param ph_move [Boolean] true: physical, false: special
    # @return [Integer]
    def flower_gift_dfe_calc(target, ph_move)
      return 1 if ph_move
      return 1 unless $env.sunny?
      return 1 unless logic.allies_of(target).any? { |ally| ally.has_ability?(:flower_gift) } || target.has_ability?(:flower_gift)

      return 1.5
    end

    # Sandstorm calculation: DFE/DFS
    # @param target [PFM::PokemonBattler] target of the move
    # @param ph_move [Boolean] true: physical, false: special
    # @return [Integer]
    def sandstorm_calc(target, ph_move)
      return 1 if ph_move
      return 1 unless $env.sandstorm? && target.type_rock?

      return 1.5
    end

    # CH calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @return [Numeric]
    def calc_ch(user)
      return 1 unless critical_hit?
      return 3 if user.has_ability?(:sniper)

      return 2
    end

    # Calc TypeN multiplier of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @param type_to_check [Symbol] type to check on the target
    # @param types [Array<Integer>] list of types the move has
    # @return [Numeric]
    def calc_type_n_multiplier(target, type_to_check, types)
      target_type = target.send(type_to_check)
      result = types.inject(1) { |product, type| product * calc_single_type_multiplier(target, target_type, type) }
      @effectiveness *= result
      return result
    end

    # Calc the single type multiplier
    # @param target [PFM::PokemonBattler] target of the move
    # @param target_type [Integer] one of the type of the target
    # @param type [Integer] one of the type of the move
    # @return [Float] definitive multiplier
    def calc_single_type_multiplier(target, target_type, type)
      exec_hooks(Move, :single_type_multiplier_overwrite, binding)
      return GameData::Type[target_type].hit_by(type)
    rescue Hooks::ForceReturn => e
      log_data("# calc_single_type_multiplier(#{target}, #{target_type}, #{type})")
      log_data("# FR: calc_single_type_multiplier #{e.data} from #{e.hook_name} (#{e.reason})")
      return e.data
    end

    # Get the types of the move with 1st type being affected by effects
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Array<Integer>] list of types of the move
    def definitive_types(user, target)
      type = self.type
      exec_hooks(Move, :move_type_change, binding)
      return [*type]
    end

    # "Calc" the R range value
    # @return [Range]
    def calc_r_range
      R_RANGE
    end

    class << self
      # Function that registers a move_type_change hook
      # @param reason [String] reason of the move_type_change registration
      # @yieldparam user [PFM::PokemonBattler]
      # @yieldparam target [PFM::PokemonBattler]
      # @yieldparam move [Battle::Move]
      # @yieldparam type [Integer] current type of the move
      # @yieldreturn [Integer, nil] new move type
      def register_move_type_change_hook(reason)
        Hooks.register(Move, :move_type_change, reason) do |hook_binding|
          result = yield(hook_binding.local_variable_get(:user), hook_binding.local_variable_get(:target), self,
                         hook_binding.local_variable_get(:type))
          hook_binding.local_variable_set(:type, result) if result.is_a?(Integer)
        end
      end

      # Function that registers a single_type_multiplier_overwrite hook
      # @param reason [String] reason of the single_type_multiplier_overwrite registration
      # @yieldparam target [PFM::PokemonBattler]
      # @yieldparam target_type [Integer] one of the type of the target
      # @yieldparam type [Integer] one of the type of the move
      # @yieldparam move [Battle::Move]
      # @yieldreturn [Float, nil] overwritten
      def register_single_type_multiplier_overwrite_hook(reason)
        Hooks.register(Move, :single_type_multiplier_overwrite, reason) do |hook_binding|
          result = yield(hook_binding.local_variable_get(:target),
                         hook_binding.local_variable_get(:target_type),
                         hook_binding.local_variable_get(:type), self)
          force_return(result) if result
        end
      end
    end

    # Not added before effects to let it being overwritten by effects ;)
    Move.register_move_type_change_hook('PSDK Normalize Ability') do |user, _, move|
      next user.has_ability?(:normalize) && move.be_method != :s_weather_ball ? GameData::Types::NORMAL : nil
    end

    Move.register_move_type_change_hook('PSDK Effect process') do |user, target, move, type|
      move.logic.each_effects(user, target) do |e|
        result = e.on_move_type_change(user, target, move, type)
        type = result if result.is_a?(Integer)
      end
      next type
    end

    # Note: added after effect to overwrite move effects ;)
    Move.register_move_type_change_hook('PSDK Pixilate Ability') do |user, _, move|
      next user.has_ability?(:pixilate) && move.type_normal? && move.be_method != :s_weather_ball ? GameData::Types::FAIRY : nil
    end

    Move.register_move_type_change_hook('PSDK Refrigerate Ability') do |user, _, move|
      next user.has_ability?(:refrigerate) && move.type_normal? && move.be_method != :s_weather_ball ? GameData::Types::ICE : nil
    end

    Move.register_move_type_change_hook('PSDK Aerilate Ability') do |user, _, move|
      next user.has_ability?(:aerilate) && move.type_normal? && move.be_method != :s_weather_ball ? GameData::Types::FLYING : nil
    end

    Move.register_move_type_change_hook('PSDK Galvanize Ability') do |user, _, move|
      next user.has_ability?(:galvanize) && move.type_normal? && move.be_method != :s_weather_ball ? GameData::Types::ELECTRIC : nil
    end

    Move.register_move_type_change_hook('PSDK Scrappy Ability') do |user, target, move|
      next user.has_ability?(:scrappy) && target.type_ghost? && (move.type_normal? || move.type_fighting?) ? 1 : nil
    end
=begin
    Move.register_move_type_change_hook('PSDK Weather Ball') do |user, target, move|
      next nil unless move.be_method == :s_weather_ball
      next nil if $env.normal? || $env.fog?
      next nil if target.has_ability?(:air_lock) || target.has_ability?(:cloud_nine)
      next GameData::Types::FIRE if $env.sunny?
      next GameData::Types::WATER if $env.rain?
      next GameData::Types::ICE if $env.hail?
      next GameData::Types::ROCK if $env.sandstorm?

      next nil
    end
=end
    # TechnoBlast
    TECHNODRIVES = {
      douse_drive: GameData::Types::WATER,
      shock_drive: GameData::Types::ELECTRIC,
      burn_drive: GameData::Types::FIRE,
      chill_drive: GameData::Types::ICE
    }
    Move.register_move_type_change_hook('PSDK Techno Blast') do |user, _, move|
      next nil unless user.db_symbol == :genesect && move.be_method == :s_techno_blast

      next TECHNODRIVES[user.item_db_symbol] || GameData::Types::NORMAL
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Effect process') do |target, target_type, type, move|
      overwrite = nil
      move.logic.each_effects(target) do |e|
        next if overwrite

        result = e.on_single_type_multiplier_overwrite(target, target_type, type, move)
        overwrite = result if result
      end
      next overwrite
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Foresight') do |target, target_type, type|
      next nil unless target.effects.has?(:foresight) && target_type == GameData::Types::GHOST
      next 1 if type == GameData::Types::NORMAL
      next 1 if type == GameData::Types::FIGHTING

      next nil
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Miracle Eye') do |target, target_type, type|
      next nil unless target.effects.has?(:miracle_eye) && target_type == GameData::Types::DARK
      next 1 if type == GameData::Types::PSYCHIC

      next nil
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Freeze-Dry') do |_, target_type, _, move|
      next 2 if move.db_symbol == :"freeze-dry" && target_type == GameData::Types::WATER

      next nil
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Gravity') do |_, target_type, type, move|
      next nil unless move.logic.terrain_effects.has?(:gravity) && target_type == GameData::Types::FLYING
      next 1 if type == GameData::Types::GROUND

      next nil
    end

    Move.register_single_type_multiplier_overwrite_hook('PSDK Grounded: Levitate & Air Balloon') do |target, _, type|
      next 0 if type == GameData::Types::GROUND && !target.grounded?

      next nil
    end
  end
end
