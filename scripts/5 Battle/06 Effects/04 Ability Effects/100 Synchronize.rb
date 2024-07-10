module Battle
  module Effects
    class Ability
      class Synchronize < Ability
        # List of status Synchronize is applying
        SYNCHRONIZED_STATUS = %i[poison toxic paralysis burn]
        # Function called when a post_status_change is performed
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_status_change(handler, status, target, launcher, skill)
          return if target != @target || launcher == target || !launcher || launcher.status == target.status
          return unless SYNCHRONIZED_STATUS.include?(status)

          handler.scene.visual.show_ability(target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 1159, launcher))
          handler.status_change_with_process(status, launcher, target)
        end
      end
      register(:synchronize, Synchronize)
    end
  end
end
