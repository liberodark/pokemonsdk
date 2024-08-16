module Battle
  module Effects
    class Ability
      class PoisonPuppeteer < Ability
        # Function called when a post_status_change is performed
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_status_change(handler, status, target, launcher, skill)
          return if launcher != @target || launcher == target || target.confused?
          return unless skill && %i[poison toxic].include?(status)

          handler.scene.visual.show_ability(launcher)
          target.effects.add(Effects::Confusion.new(handler.logic, target))
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 345, target))
        end
      end

      register(:poison_puppeteer, PoisonPuppeteer)
    end
  end
end
