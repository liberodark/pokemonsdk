module Battle
  module Effects
    # Implement the Salt Cure effect
    class SaltCure < PokemonTiedEffectBase
      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return if @pokemon.dead?
        return if @pokemon.has_ability?(:magic_guard)

        divisor = @pokemon.type_steel? || @pokemon.type_water? ? 4 : 8
        hp = (@pokemon.max_hp / divisor).clamp(1, @pokemon.hp)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 372, @pokemon, '[VAR MOVE(0001)]' => data_move(:salt_cure).name))
        logic.damage_handler.damage_change(hp, @pokemon)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :salt_cure
      end
    end
  end
end
