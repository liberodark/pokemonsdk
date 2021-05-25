module Battle::Effects
  class UpRoar < PokemonTiedEffectBase
    include ForceNextMove

    # Create a new Forced next move effect
    # @param logic [Battle::Logic]
    # @param target [PFM::PokemonBattler]
    # @param move [Battle::Move]
    # @param counter [Integer] number of turn the move is forced to be used (including the current one)
    # @param targets [Array<PFM::PokemonBattler>]
    def initialize(logic, target, move, targets, counter)
      super(logic, target)
      init_force_next_move(move, targets, counter)
      @logic.scene.display_message_and_wait(provoke_message(@pokemon))
      wake_up_pokemons
    end

    # Function called at the end of a turn
    # @param logic [Battle::Logic] logic of the battle
    # @param scene [Battle::Scene] battle scene
    # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
    def on_end_turn_event(logic, scene, battlers)
      message = triggered? ? calm_down_message(@pokemon) : continue_message(@pokemon)
      @logic.scene.display_message_and_wait(message)
    end

    # Is the effect in its last turn ?
    # @return [Boolean]
    def triggered?
      @counter == 1
    end

    # Name of the effect
    # @return [Symbol]
    def name
      :uproar
    end

    private

    # Wake up all the asleep pokemons
    def wake_up_pokemons
      @logic.all_alive_battlers.each do |battler|
        next unless battler.asleep?
        @logic.status_change_handler.status_change_with_process(:cure, battler, message_overwrite: wake_up_message_id)
      end
    end

    # Id of the message displayed when the uproar wake up a battler
    # @return [Integer]
    def wake_up_message_id
      706
    end

    # Message displayed at the beginning of the uproar
    # @param user [PFM::PokemonBattler] the user of the upraor
    # @return [String]
    def provoke_message(user)
      parse_text_with_pokemon(19, 703, user)
    end

    # Message displayed at the end of the turn when the uproar continue
    # @param user [PFM::PokemonBattler] the user of the upraor
    # @return [String]
    def continue_message(user)
      parse_text_with_pokemon(19, 715, user)
    end

    # Message displayed at the end of the uproar
    # @param user [PFM::PokemonBattler] the user of the upraor
    # @return [String]
    def calm_down_message(user)
      parse_text_with_pokemon(19, 718, user)
    end
  end
end