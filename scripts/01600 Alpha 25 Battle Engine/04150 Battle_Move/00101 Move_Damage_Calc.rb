module Battle
  class Move
    # Range of the R random factor
    R_RANGE = 85..100

    # Method calculating the damages done by the actual move
    # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @param rng [Random] random generator used for the move
    # @return [Integer]
    def damages(user, target, rng)
      @critical = logic.calc_critical_hit(user, target, critical_rate)
      # Reset the effectiveness
      @effectiveness = 1
      # (((((((Level * 2 / 5) + 2) * BasePower * [Sp]Atk / 50) / [Sp]Def) * Mod1) + 2) *
      # CH * Mod2 * R / 100) * STAB * Type1 * Type2 * Mod3)
      damage = user.level * 2 / 5 + 2
      damage = (damage * calc_base_power(user, target)).floor
      damage = (damage * calc_sp_atk(user, target)).floor
      damage /= 50
      damage = (damage / calc_sp_def(user, target)).floor
      damage = (damage * calc_mod1(user, target)).floor
      damage += 2
      damage = (damage * calc_ch(user)).floor
      damage = (damage * calc_mod2(user, target)).floor
      damage *= rng.rand(calc_r_range)
      damage /= 100
      damage = (damage * calc_stab(user)).floor
      types = definitive_types(user, target)
      damage = (damage * calc_type_n_multiplier(target, :type1, types)).floor
      damage = (damage * calc_type_n_multiplier(target, :type2, types)).floor
      damage = (damage * calc_type_n_multiplier(target, :type3, types)).floor
      return (damage * calc_mod3(user, target)).floor
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

    private

    # Base power calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Integer]
    def calc_base_power(user, target)
      # HH * BP * IT * CHG * MS * WS * UA * FA
      # BP
      result = power
      # HH
      result *= 1.5 if user.helping_hand?
      result = result.floor # Round down between each multiplication, the first two can be reverted.
      # IT
      result = (result * send(ITEM_MULTIPLIER[user.battle_item_db_symbol], user, target)).floor
      # CHG
      result *= user.last_successfull_move_is?(:charge) && type == GameData::Types::ELECTRIC ? 2 : 1
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
      result = ph_move ? user.atk_basis : user.ats_basis
      # SM (Only if non-critical hit)
      result = (result * (ph_move ? user.atk_modifier : user.ats_modifier)).floor unless critical_hit?
      # AM
      am = send((ph_move ? ATK_ABILITY_MODIFIER : ATS_ABILITY_MODIFIER)[user.battle_ability_db_symbol], user, target)
      result = (result * am).floor
      # IM
      return (result * send((ph_move ? ATK_ITEM_MODIFIER : ATS_ITEM_MODIFIER)[user.battle_item_db_symbol], user, target)).floor
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
      result = (result * (ph_move ? target.dfe_modifier : target.dfs_modifier)).floor unless critical_hit?
      # Mod
      result = (result * 1.5).floor if !ph_move && $env.sandstorm? && target.type_rock?
      mod = send((ph_move ? DFE_ABILITY_MODIFIER : DFS_ABILITY_MODIFIER)[target.battle_ability_db_symbol], user, target)
      result = (result * mod).floor
      mod = send((ph_move ? DFE_ITEM_MODIFIER : DFS_ITEM_MODIFIER)[target.battle_item_db_symbol], user, target)
      result = (result * mod).floor
      # SX
      result = (result * VAL_0_5).floor if EXPLOSION_SELF_DESTRUCT_MOVE.include?(db_symbol)
      return result
    end

    # CH calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @return [Numeric]
    def calc_ch(user)
      return 1 unless critical_hit?
      return 3 if user.has_ability?(:sniper)

      return 2
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

    # Calc TypeN multiplier of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @param type_to_check [Symbol] type to check on the target
    # @param types [Array<Integer>] list of types the move has
    # @return [Numeric]
    def calc_type_n_multiplier(target, type_to_check, types)
      user_type = target.send(type_to_check)
      result = types.inject(1) { |product, type| product * GameData::Type[user_type].hit_by(type) }
      # Foresight - Odor Sleuth
      if result == 0 && ((target.effects.has?(:foresight) && types.include?(GameData::Types::NORMAL || GameData::Types::FIGHTING)) ||
                        (target.effects.has?(:miracle_eye) && types.include?(GameData::Types::PSYCHIC)))
        result = 1
      end
      # Freeze-Dry
      result = 2 if db_symbol == :"freeze-dry" && target.type_water?
      @effectiveness *= result
      return result
    end

    # Get the types of the move with 1st type being affected by effects
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Array<Integer>] list of types of the move
    def definitive_types(user, target)
      type = self.type
      exec_hooks(Move, :move_type_change, binding)
      return [type]
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
    end

    # Not added before effects to let it being overwritten by effects ;)
    Move.register_move_type_change_hook('PSDK Normalize Ability') do |user|
      next user.has_ability?(:normalize) ? GameData::Types::NORMAL : nil
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
      next user.has_ability?(:pixilate) && move.type_normal? ? GameData::Types::FAIRY : nil
    end

    Move.register_move_type_change_hook('PSDK Refrigerate Ability') do |user, _, move|
      next user.has_ability?(:refrigerate) && move.type_normal? ? GameData::Types::ICE : nil
    end

    Move.register_move_type_change_hook('PSDK Aerilate Ability') do |user, _, move|
      next user.has_ability?(:aerilate) && move.type_normal? ? GameData::Types::FLYING : nil
    end

    Move.register_move_type_change_hook('PSDK Galvanize Ability') do |user, _, move|
      next user.has_ability?(:galvanize) && move.type_normal? ? GameData::Types::ELECTRIC : nil
    end
  end
end
