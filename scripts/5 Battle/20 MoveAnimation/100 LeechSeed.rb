ya = Yuki::Animation
# Leech Seed

animation_target = ya.wait(0)
animation_user = ya.se_play('moves/leech-seed-1')
animation_user.play_before(ya.wait(0.8))
animation_user.play_before(ya.send_command_to(:target, :center_camera))
animation_user.play_before(ya.wait(1.5))
animation_user.play_before(ya.send_command_to(:visual, :start_center_animation))

# Seeds Animation
seed_throw_animation = ya.wait(0.7)
4.times do |i|
  seed_symbol = :"seed_#{i}"
  seed_animation = ya.create_sprite(:viewport, seed_symbol, Sprite, nil, [:load, 'seed', :animation], [:opacity=, 255],
                                    [:zoom=, 0], [:set_origin, 16, 16])
  seed_animation_resolved = ya.resolved
  seed_animation.play_before(seed_animation_resolved)
  seed_animation_resolved.play_before(ya.wait(0.2 * i))
  seed_animation_resolved.play_before(ya.particle_random_sprite_command(seed_symbol, :user, 0, 0))

  # Zoom animation
  zoom_animation = ya.particle_zoom_x(0.5, seed_symbol, :target, 0, 0.7)
  zoom_animation.parallel_add(ya.particle_zoom_y(0.5, seed_symbol, :target, 0, 1))
  zoom_animation.play_before(ya.particle_zoom_x(0.2, seed_symbol, :target, 0.7, 0)
                .parallel_add(ya.particle_zoom_y(0.2, seed_symbol, :target, 1, 0)))

  rotation_animation = ya.rotation(0.8, seed_symbol, 0, 1440)

  combined_animation = ya.wait(0.5)
  combined_animation.parallel_add(zoom_animation)
  combined_animation.parallel_add(rotation_animation)
  combined_animation.parallel_add(ya.particle_move_to_sprite(0.7, seed_symbol, :user, :target, 0, 0))
  combined_animation.parallel_add(ya.scalar_offset(0.7, seed_symbol, :y, :y=, 20, -64, distortion: :SQUARE010_DISTORTION))

  seed_animation_resolved.play_before(combined_animation)

  seed_animation.play_before(ya.dispose_sprite(seed_symbol))
  seed_throw_animation.parallel_add(seed_animation)
end

# Seeds Growth Animation
position_array = [[0, 0], [-21, -3], [21, 3]]
seeds_growth_animations = ya.wait(1.5)
3.times do |i|
  growth_symbol = "growth_#{i}".to_sym
  growth_animation = ya.create_sprite(:viewport, growth_symbol, Sprite, nil, [:load, 'seed-growth', :animation], [:opacity=, 255],
                                      [:zoom=, 0], [:set_origin, 16, 32], [:set_rect, 0, 0, 32, 32])
  growth_animation_resolved = ya.resolved
  growth_animation.play_before(ya.wait(0.6))
  growth_animation.play_before(growth_animation_resolved)

  growth_animation_resolved.play_before(ya.particle_on_sprite_command(growth_symbol, :target, *position_array[i]))
  growth_animation_resolved.play_before(ya.tone_animation(0, growth_symbol, [0.08, 0.94, 0.05, 0.83]))
  growth_animation_resolved.play_before(ya.wait(0.1 * i))
  growth_animation_resolved.play_before(ya.particle_zoom(0, growth_symbol, :target, 0, 1))
  5.times do |j|
    growth_animation_resolved.play_before(ya.wait(0.05))
    growth_animation_resolved.play_before(ya.send_command_to(growth_symbol, :set_rect, 32 * j, 0, 32, 32))
  end
  growth_animation_resolved.play_before(ya.wait(0.2))
  growth_animation_resolved.play_before(ya.opacity_change(0.3, growth_symbol, 255, 0))

  growth_animation.play_before(ya.dispose_sprite(growth_symbol))
  seeds_growth_animations.parallel_add(growth_animation)
end

animation_target.play_before(seeds_growth_animations
                .parallel_add(seed_throw_animation))

Battle::MoveAnimation.register_specific_animation(:leech_seed, :first_use, animation_user, animation_target)
