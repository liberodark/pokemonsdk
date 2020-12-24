module Battle
  class Logic
    private

    # Perform the attack action
    # @param action [Hash] action data
    def perform_action_attack(action)
      action[:skill].proceed(action[:launcher], action[:target_bank], action[:target_position])
    end

    # Perform the mega action (Mega-evolving)
    # @param action [Hash] action data
    def perform_action_mega(action)
      # TODO
    end

    # Perform the action of using an item
    # @param action [Hash] action data
    def perform_action_item(action)
      # @type [PFM::ItemDescriptor::Wrapper]
      item_wrapper = action[:item_wrapper]
      # @type [PFM::Bag]
      bag = action[:bag]
      bag.remove_item(item_wrapper.item.id, 1) if item_wrapper.item.limited
      item_wrapper.execute_battle_action
    end

    # Perform the action of switching
    # @param action [Hash] action data
    def perform_action_switch(action)
      # @type [PFM::PokemonBattler]
      who = action[:who]
      # @type [PFM::PokemonBattler]
      with = action[:with]
      visual = @scene.visual
      # @type [BattleUI::PokemonSprite]
      (sprite = visual.battler_sprite(who.bank, who.position)).go_out
      visual.hide_info_bar(who)
      until sprite.done?
        visual.update
        Graphics.update
      end
      # Logically switching the Pokemon
      switch_battlers(who, with)
      # Switching the sprite
      sprite.pokemon = with
      sprite.start_animation_going_out
      visual.show_info_bar(with)
      until sprite.done?
        visual.update
        Graphics.update
      end
      switch_handler.execute_switch_events(who, with)
    end

    # Perform the action of fleeing (Roaming Pokemon)
    # @param action [Hash] action data
    def perform_action_flee(action)
      # TODO
    end
  end
end
