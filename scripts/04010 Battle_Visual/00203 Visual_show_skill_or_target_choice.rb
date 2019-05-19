module Battle
  class Visual
    # Method that show the skill choice and store it inside an instance variable
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    # @return [Boolean] if the player has choose a skill
    def show_skill_choice(pokemon_index)
      # return :try_next if spc_cannot_use_this_pokemon?(pokemon_index)
      show_skill_choice_begin(pokemon_index)
      show_skill_choice_loop
      show_skill_choice_end(pokemon_index)
      return @skill_choice_ui.result != :cancel
    end

    # Method that show the target choice once the skill was choosen
    # @return [Array<PFM::PokemonBattler, Battle::Move, Integer(bank), Integer(position)>, nil]
    def show_target_choice

    end

    private

    # Begin of the skill_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_skill_choice_begin(pokemon_index)
      @locking = true
      @skill_choice_ui.reset(@battle_scene.logic.battler(0, pokemon_index))
      @skill_choice_ui.visible = true
      @battle_scene.message_window.visible = false
      spc_start_bouncing_animation(pokemon_index)
    end

    # Loop of the skill_choice
    def show_skill_choice_loop
      loop do
        @battle_scene.update
        @skill_choice_ui.update
        Graphics.update
        break if @skill_choice_ui.validated?
      end
    end

    # End of the skill_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_skill_choice_end(pokemon_index)
      spc_stop_bouncing_animation(pokemon_index)
      @battle_scene.message_window.visible = true
      @skill_choice_ui.visible = false
      @locking = false
    end
  end
end
