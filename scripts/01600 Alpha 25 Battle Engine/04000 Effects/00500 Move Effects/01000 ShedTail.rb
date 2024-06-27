module Battle
  module Effects
    class ShedTail < PokemonTiedEffectBase
      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        who.effects.get(:substitute).on_baton_pass_switch(with)
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :shed_tail
      end
    end
  end
end
