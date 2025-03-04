ya = Yuki::Animation
# Stun Store

all_animations = []

camera_move_animation = ya.camera_move_animation(:target)
camera_move_animation.play_before(ya.se_play('moves/sleep-powder'))
all_animations << camera_move_animation

# Big Particles Animation
animation = ya.wait(1.5)
20.times do |i|
  particle_symbol = "particle_#{i}".to_sym
  parallel_animation = ya.create_sprite(:viewport, particle_symbol, Sprite, nil, [:load, 'Circle-blurry-M-2', :animation],
                                        [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16])
  animation_resolved = ya.resolved
  parallel_animation.play_before(animation_resolved)

  animation_resolved.play_before(ya.tone_animation(0, particle_symbol, [0, 0.94, 0.58, 0.83]))
  animation_resolved.play_before(ya.wait(0.2 * i / 5))
  animation_resolved.play_before(ya.particle_zoom(0, particle_symbol, :target, 0, 0.5))

  opacity_animation = ya.wait(0.8)
  opacity_animation.play_before(ya.opacity_change(0.3, particle_symbol, 255, 0))

  move_animation = ya.scalar_x_from_sprite(1.2, particle_symbol, :target, 0, 15, distortion: :"POWDER_#{i % 5 + 1}")
  move_animation.parallel_add(ya.falling_animation(1.2, particle_symbol, :target, 80, distortion: :UNICITY_DISTORTION))
  move_animation.parallel_add(ya.particle_zoom(1.2, particle_symbol, :target, 0.7, 0.3, distortion: :POSITIVE_OSCILLATING_16))
  move_animation.parallel_add(opacity_animation)

  animation_resolved.play_before(move_animation)

  parallel_animation.play_before(ya.dispose_sprite(particle_symbol))
  animation.parallel_add(parallel_animation)
end

# Pokemon Sprite Animation
pokemon_animation = ya.resolved
pokemon_animation.play_before(ya.wait(0.5))
pokemon_animation.play_before(ya.send_command_to(:target, :stop_gif_animation=, true))
pokemon_animation.play_before(ya.send_command_to(:target, :set_tone_to, 0, 0.94, 0.58, 0.6))
pokemon_animation.play_before(ya.compress(0.15, :target, -0.2, 0.2, iteration: 5))
pokemon_animation.play_before(ya.send_command_to(:target, :reset_tone_status))
pokemon_animation.play_before(ya.send_command_to(:target, :stop_gif_animation=, false))

animation.parallel_add(pokemon_animation)
all_animations << animation

# Camera reset
camera_reset_position = ya.camera_reset_position
all_animations << camera_reset_position

animation_target = ya.combine_before_animation(all_animations)

Battle::MoveAnimation.register_specific_animation(:sleep_powder, :first_use, ya.wait(0), animation_target)
