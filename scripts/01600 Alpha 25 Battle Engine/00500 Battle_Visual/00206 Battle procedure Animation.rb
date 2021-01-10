module Battle
  class Visual
    # Show HP animations
    # @param targets [Array<PFM::PokemonBattler>]
    # @param hps [Array<Integer>]
    # @param effectiveness [Array<Integer, nil>]
    # @param messages [Proc] messages shown right before the post processing
    def show_hp_animations(targets, hps, effectiveness = [], &messages)
      lock do
        animations = targets.map.with_index do |target, index|
          show_info_bar(target)
          next Battle::Visual::HPAnimation.new(@scene, target, hps[index], effectiveness[index]) if hps[index]
        end
        wait_for_animation
        scene_update_proc { animations.each(&:update) } until animations.all?(&:done?)
        messages&.call
        show_kos(targets)
      end
    end

    # Show KO animations
    # @param targets [Array<PFM::PokemonBattler>]
    def show_kos(targets)
      targets = targets.select(&:dead?)
      return if targets.empty?

      Audio.se_play('Audio/SE/Down.wav', 100, 80)
      # Start all animations
      targets.each do |target|
        battler_sprite(target.bank, target.position).go_out
        hide_info_bar(target)
      end
      # Show messages
      targets.each do |target|
        @scene.display_message(parse_text_with_pokemon(19, 0, target, PFM::Text::PKNICK[0] => target.given_name))
        target.reset_stat_stage
        target.status = 0
      end
    end

    # Show the ability animation
    # @param target [PFM::PokemonBattler]
    def show_ability(target)
      ability_bar = @ability_bars[target.bank][target.position]
      item_bar = @item_bars[target.bank][target.position]
      return unless ability_bar

      ability_bar.data = target
      ability_bar.go_in
      if !item_bar || item_bar.done?
        ability_bar.z = 0
      else
        ability_bar.z = item_bar.z + 1
      end
    end

    # Show the item user animation
    # @param target [PFM::PokemonBattler]
    def show_item(target)
      ability_bar = @ability_bars[target.bank][target.position]
      item_bar = @item_bars[target.bank][target.position]
      return unless item_bar

      item_bar.data = target
      item_bar.go_in
      item_bar.z = ability_bar.z + 1 unless !ability_bar || ability_bar.done?
      if !ability_bar || ability_bar.done?
        item_bar.z = 0
      else
        item_bar.z = ability_bar.z + 1
      end
    end

    # Show the pokemon switch form animation
    # @param target [PFM::PokemonBattler]
    def show_switch_form_animation(target)
      # TODO: Implement an animation for that & write the code
    end

    # Make a move animation
    # @param user [PFM::PokemonBattler]
    # @param targets [Array<PFM::PokemonBattler>]
    # @param move [Battle::Move]
    def show_move_animation(user, targets, move)
      return unless $options.show_animation

      $data_animations ||= load_data('Data/Animations.rxdata')
      id = move.id
      user_sprite = battler_sprite(user.bank, user.position)
      target_sprite = battler_sprite(targets.first.bank, targets.first.position)
      original_rect = @viewport.rect.clone
      @viewport.rect.height = Viewport::CONFIGS[:main][:height]
      lock { @move_animator.move_animation(user_sprite, target_sprite, id, user.bank != 0) }
      @viewport.rect = original_rect
    end

    # Show a dedicated animation
    # @param target [PFM::PokemonBattler]
    # @param id [Integer]
    def show_rmxp_animation(target, id)
      return unless $options.show_animation

      wait_for_animation
      $data_animations ||= load_data('Data/Animations.rxdata')
      lock { @move_animator.animation(battler_sprite(target.bank, target.position), id, target.bank != 0) }
    end

    # Show the exp distribution
    # @param exp_data [Hash{ PFM::PokemonBattler => Integer }] info about experience each pokemon should receive
    def show_exp_distribution(exp_data)
      lock do
        @scene.message_window.visible = false
        exp_ui = BattleUI::ExpDistribution.new(@viewport_sub, @scene, exp_data)
        exp_ui.start_animation
        scene_update_proc { exp_ui.update } until exp_ui.done?
        exp_ui.dispose
      end
      exp_data.each_key { |pokemon| refresh_info_bar(pokemon) if @scene.battle_info.vs_type > pokemon.position }
    end
  end
end
