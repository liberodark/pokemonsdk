module Battle
  module Effects
    # Class that describe the bind effect
    class Bind < PokemonTiedEffectBase
      # Hash giving the message info based on the db_symbol of the move
      MESSAGE_INFO = {
        bind: [19, 806, true],
        wrap: [19, 813, true],
        fire_spin: [19, 830, false],
        clamp: [19, 820, true],
        whirlpool: [19, 827, false],
        sand_tomb: [19, 836, false],
        magma_storm: [19, 833, false],
        infestation: [19, 1234, true],
        octolock: [59, 1978, false],
        snap_trap: [59, 1974, false],
        thunder_cage: [59, 2052, true]
      }
      # The Pokemon that launched the attack
      # @return [PFM::PokemonBattler]
      attr_reader :origin

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      # @param turn_count [Integer]
      # @param move [Battle::Move] move responsive of the effect
      def initialize(logic, pokemon, origin, turn_count, move)
        super(logic, pokemon)
        @origin = origin
        @move = move
        self.counter = turn_count
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return kill if @origin.dead?
        return if @pokemon.dead?
        return if @pokemon.has_ability?(:magic_guard)

        scene.display_message(message)
        logic.damage_handler.damage_change((@pokemon.max_hp / hp_factor).clamp(1, Float::INFINITY), @pokemon)
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @param reason [Symbol] the reason why the SwitchHandler is called
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill, reason)
        return if pokemon != @pokemon
        return kill if @origin.dead?

        return handler.prevent_change do
          handler.scene.display_message_and_wait(message)
        end
      end

      # Function called when a Pokemon has actually switched with another one
      # @param _handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param _with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(_handler, who, _with)
        kill if who == @origin
      end

      # Tell if the effect is dead or must be cleared
      # @return [Boolean]
      def dead?
        super || !@origin.can_fight?
      end

      # Function that tells if the move is affected by Rapid Spin
      # @return [Boolean]
      def rapid_spin_affected?
        return true
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :bind
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 375, @pokemon, PFM::Text::MOVE[1] => @move.name))
      end

      private

      # Get the message text
      # @return [String]
      def message
        file_id, message_id, two_pokemon_message = (MESSAGE_INFO[@move.db_symbol] || [0, 0, false])
        return parse_text_with_2pokemon(file_id, message_id, @pokemon, @origin) if two_pokemon_message

        return parse_text_with_pokemon(file_id, message_id, @pokemon)
      end

      # Get the HP factor delt by the move
      # @return [Integer]
      def hp_factor
        return @origin.hold_item?(:binding_band) ? 8 : 6
      end
    end
  end
end
