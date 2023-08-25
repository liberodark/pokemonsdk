module PFM
  class PokemonBattler
    # Minimal value of the stat modifier level (stage)
    MIN_STAGE = -6
    # Maximal value of the stat modifier level (stage)
    MAX_STAGE = 6

    # Return the current atk
    # @return [Integer]
    def atk
      raw_atk = (atk_basis * atk_modifier).floor

      return @scene.logic.each_effects(self).reduce(raw_atk) do |product, e|
        (product * e.atk_modifier).floor
      end
    end

    # Return the current dfe
    # @return [Integer]
    def dfe
      raw_dfe = (dfe_basis * dfe_modifier).floor
      return @scene.logic.each_effects(self).reduce(raw_dfe) do |product, e|
        (product * e.dfe_modifier).floor
      end
    end

    # Return the current spd
    # @return [Integer]
    def spd
      raw_spd = (spd_basis * spd_modifier).floor
      return @scene.logic.each_effects(self).reduce(raw_spd) do |product, e|
        (product * e.spd_modifier).floor
      end
    end

    # Return the current ats
    # @return [Integer]
    def ats
      raw_ats = (ats_basis * ats_modifier).floor
      return @scene.logic.each_effects(self).reduce(raw_ats) do |product, e|
        (product * e.ats_modifier).floor
      end
    end

    # Return the current dfs
    # @return [Integer]
    def dfs
      raw_dfs = (dfs_basis * dfs_modifier).floor
      return @scene.logic.each_effects(self).reduce(raw_dfs) do |product, e|
        (product * e.dfs_modifier).floor
      end    
    end

    # Return the atk modifier
    # @return [Float] the multiplier
    def atk_modifier
      return stat_multiplier_regular(atk_stage)
    end

    # Return the dfe modifier
    # @return [Float] the multiplier
    def dfe_modifier
      return stat_multiplier_regular(dfe_stage)
    end

    # Return the spd modifier
    # @return [Float] the multiplier
    def spd_modifier
      return stat_multiplier_regular(spd_stage)
    end

    # Return the ats modifier
    # @return [Float] the multiplier
    def ats_modifier
      return stat_multiplier_regular(ats_stage)
    end

    # Return the dfs modifier
    # @return [Float] the multiplier
    def dfs_modifier
      return stat_multiplier_regular(dfs_stage)
    end

    # Return the atk stage
    # @return [Integer]
    def atk_stage
      return @battle_stage[Configs.stats.atk_stage_index]
    end

    # Return the dfe stage
    # @return [Integer]
    def dfe_stage
      return @battle_stage[Configs.stats.dfe_stage_index]
    end

    # Return the spd stage
    # @return [Integer]
    def spd_stage
      return @battle_stage[Configs.stats.spd_stage_index]
    end

    # Return the ats stage
    # @return [Integer]
    def ats_stage
      return @battle_stage[Configs.stats.ats_stage_index]
    end

    # Return the dfs stage
    # @return [Integer]
    def dfs_stage
      return @battle_stage[Configs.stats.dfs_stage_index]
    end

    # Return the evasion stage
    # @return [Integer]
    def eva_stage
      return @battle_stage[Configs.stats.eva_stage_index]
    end

    # Return the accuracy stage
    # @return [Integer]
    def acc_stage
      return @battle_stage[Configs.stats.acc_stage_index]
    end

    # Return the regular stat multiplier
    # @param stage [Integer] the value of the stage
    # @return [Float] the multiplier
    def stat_multiplier_regular(stage)
      if stage >= 0
        return (2 + stage) / 2.0
      else
        return 2.0 / (2 - stage)
      end
    end

    # Return the accuracy related stat multiplier
    # @param stage [Integer] the value of the stage
    # @return [Float] the multiplier
    def stat_multiplier_acceva(stage)
      if stage >= 0
        return (3 + stage) / 3.0
      else
        return 3.0 / (3 - stage)
      end
    end

    # Change a stat stage
    # @param stat_id [Integer] id of the stat : 0 = atk, 1 = dfe, 2 = spd, 3 = ats, 4 = dfs, 5 = eva, 6 = acc
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_stat(stat_id, amount)
      last_value = @battle_stage[stat_id]
      @battle_stage[stat_id] = (@battle_stage[stat_id] + amount).clamp(MIN_STAGE, MAX_STAGE)
      return @battle_stage[stat_id] - last_value
    end

    # Change the atk stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_atk(amount)
      return change_stat(Configs.stats.atk_stage_index, amount)
    end

    # Change the dfe stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_dfe(amount)
      return change_stat(Configs.stats.dfe_stage_index, amount)
    end

    # Change the spd stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_spd(amount)
      return change_stat(Configs.stats.spd_stage_index, amount)
    end

    # Change the ats stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_ats(amount)
      return change_stat(Configs.stats.ats_stage_index, amount)
    end

    # Change the dfs stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_dfs(amount)
      return change_stat(Configs.stats.dfs_stage_index, amount)
    end

    # Change the eva stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_eva(amount)
      return change_stat(Configs.stats.eva_stage_index, amount)
    end

    # Change the acc stage
    # @param amount [Integer] the amount to change on the stat stage
    # @return [Integer] the difference between the current and the last stage value
    def change_acc(amount)
      return change_stat(Configs.stats.acc_stage_index, amount)
    end

    # Set a stat stage
    # @param stat_id [Integer] id of the stat : 0 = atk, 1 = dfe, 2 = spd, 3 = ats, 4 = dfs, 5 = eva, 6 = acc
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def set_stat_stage(stat_id, value)
      return @battle_stage[stat_id] = value.clamp(MIN_STAGE, MAX_STAGE)
    end

    # Set the acc stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def acc_stage=(value)
      return set_stat_stage(Configs.stats.acc_stage_index, value)
    end

    # Set the spd stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def spd_stage=(value)
      return set_stat_stage(Configs.stats.spd_stage_index, value)
    end

    # Set the atk stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def atk_stage=(value)
      return set_stat_stage(Configs.stats.atk_stage_index, value)
    end

    # Set the ats stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def ats_stage=(value)
      return set_stat_stage(Configs.stats.ats_stage_index, value)
    end

    # Set the dfe stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def dfe_stage=(value)
      return set_stat_stage(Configs.stats.dfe_stage_index, value)
    end

    # Set the dfs stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def dfs_stage=(value)
      return set_stat_stage(Configs.stats.dfs_stage_index, value)
    end

    # Set the eva stage
    # @param value [Integer] the new value of the stat stage
    # @return [Integer] the new stat stage value
    def eva_stage=(value)
      return set_stat_stage(Configs.stats.eva_stage_index, value)
    end
  end
end
