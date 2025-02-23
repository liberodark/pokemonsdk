ya = Yuki::Animation
# Karate Chop
all_animations = []

setup_animation = Yuki::Animation::UserBankRelativeAnimation.new
setup_animation.play_before_on_bank(0, ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'hand-front-left', :animation],
                                                        [:set_rect, 0, 0, 32, 32], [:zoom=, 1], [:opacity=, 0], [:set_origin, 16, 32]))
setup_animation.play_before_on_bank(1, ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'hand-front-right', :animation],
                                                        [:set_rect, 0, 0, 32, 32], [:zoom=, 2], [:opacity=, 0], [:set_origin, 16, 32]))
all_animations << setup_animation

# Falling hand animation
fall_animation = ya.resolved
fall_animation.play_before(ya.falling_animation(1, :sprite, :target, 200))
all_animations << fall_animation

# Change Sprite and opacity color
sprite_animation = ya.resolved
sprite_animation.play_before(ya.send_command_to(:sprite, :opacity=, 200))
sprite_animation.play_before(ya.wait(0.2))
sprite_animation.play_before(ya.send_command_to(:sprite, :set_rect, 0, 32, 32, 32))
sprite_animation.play_before(ya.wait(0.2))
sprite_animation.play_before(ya.send_command_to(:sprite, :opacity=, 230))
sprite_animation.play_before(ya.send_command_to(:sprite, :set_rect, 0, 0, 32, 32))
sprite_animation.play_before(ya.wait(0.3))
sprite_animation.play_before(ya.opacity_change(0.3, :sprite, 230, 0))
all_animations << sprite_animation

# Deformation sprite
deformation_animation = ya.resolved
deformation_animation.play_before(ya.wait(0.1))
deformation_animation.play_before(ya.compress(0.3, :target, 0.2, -0.6))
all_animations << deformation_animation

# Particle Animation after hit

all_particles_animation = ya.wait(0.6)
20.times do |i|
  sprite_symbol = :"sprite_#{i}"
  particle_animation = ya.create_sprite(:viewport, sprite_symbol, Sprite, nil, [:load, 'circle_particle', :animation],
                                        [:opacity=, 0], [:set_origin, 8, 8])
  particle_anim_resolved = ya.resolved
  particle_animation.play_before(particle_anim_resolved)
  particle_animation.play_before(ya.wait(0.2))
  particle_animation.play_before(ya.send_command_to(sprite_symbol, :opacity=, 255))

  # radial Animation of the particle
  radial_animation = ya.radius_move(0.5, sprite_symbol, :target, 60)
  radial_animation.parallel_add(ya.tone_animation(0.5, sprite_symbol, [1, 0.65, 0, 1]))
  radial_animation.parallel_add(ya.scalar(0.5, sprite_symbol, :zoom=, 1, 0))

  particle_animation.play_before(radial_animation)
  particle_animation.play_before(ya.dispose_sprite(sprite_symbol))
  all_particles_animation.parallel_add(particle_animation)
end
all_animations << all_particles_animation

# Combine animation
animation_user = ya.camera_move_animation
animation_user.play_before(ya.combine_animation_with_sound('moves/karate-chop', all_animations, 1.1))
animation_user.play_before(ya.dispose_sprite(:sprite))
animation_user.play_before(ya.camera_reset_position)

Battle::MoveAnimation.register_specific_animation(:karate_chop, :first_use, animation_user, ya.wait(0))
