module Battle
  module Effects
    # Implement the Grudge effect
    class Grudge < PokemonTiedEffectBase
      # Function called after damages were applied and when target died (post_damage_death)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, hp, target, launcher, skill)
        return if target != @pokemon
        return unless launcher && skill&.direct?
        return unless target.successful_move_history.last.move.be_method == :s_grudge

        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 635, launcher, ::PFM::Text::MOVE[1] => skill.name))
        skill.pp = 0
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        kill if who == @pokemon
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead?

        kill
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :grudge
      end
    end
  end
end
