module BattleEngine
  class MessageInterpter
    private

    # Change the atk
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_atk(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:atk, power, target, @launcher, @skill)
    end

    # Change the dfe
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_dfe(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:dfe, power, target, @launcher, @skill)
    end

    # Change the spd
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_spd(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:spd, power, target, @launcher, @skill)
    end

    # Change the dfs
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_dfs(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:dfs, power, target, @launcher, @skill)
    end

    # Change the ats
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_ats(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:ats, power, target, @launcher, @skill)
    end

    # Change the eva
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_eva(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:eva, power, target, @launcher, @skill)
    end

    # Change the acc
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_acc(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @scene.logic.stat_change_handler.stat_change_with_process(:acc, power, target, @launcher, @skill)
    end
  end
end
