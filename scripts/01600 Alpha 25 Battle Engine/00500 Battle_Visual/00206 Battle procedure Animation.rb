module Battle
  class Visual
    # Show HP animations
    # @param targets [Array<PFM::PokemonBattler>]
    # @param hps [Array<Integer>]
    # @param effectiveness [Array<Integer, nil>]
    def show_hp_animations(targets, hps, effectiveness = [])
      lock do
        animations = targets.map.with_index do |target, index|
          Battle::Visual::HPAnimation.new(@scene, target, hps[index], effectiveness[index]) if hps[index]
        end
        scene_update_proc { animations.each(&:update) } until animations.all?(&:done?)
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
        battler_sprite(target.bank, target.position).start_animation_KO
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
      # TODO: write the code
    end

    # Show the item user animation
    # @param target [PFM::PokemonBattler]
    def show_item(target)
      # TODO: Implement an animation for that & write the code
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

      $data_animations ||= load_data('Data/Animations.rxdata')
      lock { @move_animator.animation(battler_sprite(target.bank, target.position), id, target.bank != 0) }
    end

    # Show the distribute exp animation
    # @param target [PFM::PokemonBattler]
    # @param target_exp [Integer] exp the Pokemon should get
    def show_exp_animation(target, target_exp)
      original_exp = target.exp
      exp_rate = target.exp_rate
      target.exp = target_exp
      time_to_process = (target.exp_rate - exp_rate) * 2
      lock do
        animation = Yuki::Animation::DiscreetAnimation.new(time_to_process, target, :exp=, original_exp, target_exp)
        animation.start
        Audio.se_play('audio/se/exp_sound')
        until animation.done?
          scene_update_proc do
            animation.update
            refresh_info_bar(target)
          end
        end
        Audio.se_stop
      end
    end
  end
end
