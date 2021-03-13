module BattleEngine
  class MessageInterpter
    private

    # Confuse the target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean] if forced by a move
    # @param msg_id [Integer]
    def status_confuse(target, forced = false, msg_id = 345)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:confusion, target, @launcher, @skill, message_overwrite: msg_id)
    end

    # Put a target asleep
    # @param target [PFM::PokemonBattler]
    # @param nb_turn [Integer, nil]
    # @param msg_id [Integer]
    # @param forced [Boolean]
    def status_sleep(target, nb_turn = nil, msg_id = 306, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:sleep, target, @launcher, @skill, message_overwrite: msg_id)
    end

    # Freeze a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_frozen(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:freeze, target, @launcher, @skill)
    end

    # Poison a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_poison(target, forced = false)
      return if @ignore or target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:poison, target, @launcher, @skill)
    end

    # Intoxicate a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_toxic(target, forced = false)
      return if @ignore or target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:toxic, target, @launcher, @skill)
    end

    # Paralyze a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_paralyze(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:paralysis, target, @launcher, @skill)
    end

    # Burn a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_burn(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      @logic.status_change_handler.status_change_with_process(:burn, target, @launcher, @skill)
    end

    # Heal the target
    # @param target [PFM::PokemonBattler]
    def status_cure(target)
      return if @ignore || target.hp <= 0
      return if target.status == 0

      @logic.status_change_handler.status_change_with_process(:cure, target, @launcher, @skill)
    end

    # Force heal a frozen target
    # @param target [PFM::PokemonBattler]
    def ice_cure(target)
      return if @ignore || target.hp <= 0 || !target.frozen?

      status_cure(target)
    end

    # Force a status on the target
    # @param target [PFM::PokemonBattler]
    # @param status [Integer] ID of teh status
    def set_status(target, status)
      target.status = status
    end
  end
end
