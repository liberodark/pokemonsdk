module PFM
  class Pokemon
    # Return the list of EV the pokemon gives when beaten
    # @return [Array<Integer>] ev list (used in bonus functions) : [hp, atk, dfe, spd, ats, dfs]
    def battle_list
      data = get_data
      return [data.ev_hp, data.ev_atk, data.ev_dfe, data.ev_spd, data.ev_ats, data.ev_dfs]
    end

    # Add ev bonus to a Pokemon (with item interaction : x2)
    # @param list [Array<Integer>] an ev list  : [hp, atk, dfe, spd, ats, dfs]
    # @return [Boolean, nil] if the ev had totally been added or not (nil = couldn't be added at all)
    def add_bonus(list)
      return nil if egg?

      stats = Configs.stats
      # Bracelet Macho
      n = item_db_symbol == :macho_brace ? 2 : 1
      r = add_ev_hp(list[stats.hp_index] * n, total_ev)
      r &= add_ev_atk(list[stats.atk_index] * n, total_ev)
      r &= add_ev_dfe(list[stats.dfe_index] * n, total_ev)
      r &= add_ev_spd(list[stats.spd_index] * n, total_ev)
      r &= add_ev_ats(list[stats.ats_index] * n, total_ev)
      r &= add_ev_dfs(list[stats.dfs_index] * n, total_ev)
      return r
    end

    # Add ev bonus to a Pokemon (without item interaction)
    # @param list [Array<Integer>] an ev list  : [hp, atk, dfe, spd, ats, dfs]
    # @return [Boolean, nil] if the ev had totally been added or not (nil = couldn't be added at all)
    def edit_bonus(list)
      return nil if egg?

      stats = Configs.stats
      r = add_ev_hp(list[stats.hp_index], total_ev)
      r &= add_ev_atk(list[stats.atk_index], total_ev)
      r &= add_ev_dfe(list[stats.dfe_index], total_ev)
      r &= add_ev_spd(list[stats.spd_index], total_ev)
      r &= add_ev_ats(list[stats.ats_index], total_ev)
      r &= add_ev_dfs(list[stats.dfs_index], total_ev)
      return r
    end

    # Return the total amount of EV
    # @return [Integer]
    def total_ev
      return @ev_hp + @ev_atk + @ev_dfe + @ev_spd + @ev_ats + @ev_dfs
    end

    # Automatic ev adder using an index
    # @param index [Integer] ev index (see GameData::EV), should add 10. If index > 10 take index % 10 and add only 1 EV.
    # @param apply [Boolean] if the ev change is applied
    # @param count [Integer] number of EV to add
    # @return [Integer, false] if not false, the value of the current EV depending on the index
    def ev_check(index, apply = false, count = 1)
      evs = total_ev
      return false if evs >= Configs.stats.max_total_ev

      if index >= 10
        index = index % 10
        return (ev_var(index, evs, apply ? count : 0) < Configs.stats.max_stat_ev)
      else
        return (ev_var(index, evs, apply ? 10 : 0) < 100)
      end
    end

    # Get and add EV
    # @param index [Integer] ev index (see GameData::EV)
    # @param evs [Integer] the total ev
    # @param value [Integer] the quantity of EV to add (if 0 no add)
    # @return [Integer]
    def ev_var(index, evs, value = 0)
      stats = Configs.stats
      case index
      when stats.hp_index
        add_ev_hp(value, evs) if value > 0
        return @ev_hp
      when stats.atk_index
        add_ev_atk(value, evs) if value > 0
        return @ev_atk
      when stats.dfe_index
        add_ev_dfe(value, evs) if value > 0
        return @ev_dfe
      when stats.spd_index
        add_ev_spd(value, evs) if value > 0
        return @ev_spd
      when stats.ats_index
        add_ev_ats(value, evs) if value > 0
        return @ev_ats
      when stats.dfs_index
        add_ev_dfs(value, evs) if value > 0
        return @ev_dfs
      else
        return 0
      end
    end

    # Safely add HP EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_hp(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_hp > Configs.stats.max_stat_ev - 1

      @ev_hp += n
      @ev_hp = @ev_hp.clamp(0, Configs.stats.max_stat_ev)
      @hp = (@hp_rate * max_hp).round
      @hp_rate = @hp.to_f / max_hp
      return true
    end

    # Safely add ATK EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_atk(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_atk > Configs.stats.max_stat_ev - 1

      @ev_atk += n
      @ev_atk = @ev_atk.clamp(0, Configs.stats.max_stat_ev)
      return true
    end

    # Safely add DFE EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_dfe(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_dfe > Configs.stats.max_stat_ev - 1

      @ev_dfe += n
      @ev_dfe = @ev_dfe.clamp(0, Configs.stats.max_stat_ev)
      return true
    end

    # Safely add SPD EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_spd(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_spd > Configs.stats.max_stat_ev - 1

      @ev_spd += n
      @ev_spd = @ev_spd.clamp(0, Configs.stats.max_stat_ev)
      return true
    end

    # Safely add ATS EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_ats(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_ats > Configs.stats.max_stat_ev - 1

      @ev_ats += n
      @ev_ats = @ev_ats.clamp(0, Configs.stats.max_stat_ev)
      return true
    end

    # Safely add DFS EV
    # @param n [Integer] amount of EV to add
    # @param evs [Integer] total ev
    # @return [Boolean] if the ev has successfully been added
    def add_ev_dfs(n, evs)
      return true if n == 0

      n -= 1 while (evs + n) > Configs.stats.max_total_ev
      return false if @ev_dfs > Configs.stats.max_stat_ev - 1

      @ev_dfs += n
      @ev_dfs = @ev_dfs.clamp(0, Configs.stats.max_stat_ev)
      return true
    end
  end
end
