ya = Yuki::Animation
# AquaRing
animation_target = ya.wait(0.1)
animation_user = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'aqua_ring', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 0.75], [:set_origin, 52, 132])
main_t_anim = ya.resolved
animation_user.play_before(main_t_anim)
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :user, :user))
main_t_anim.play_before(ya.se_play('moves/aqua_ring'))
main_t_anim.play_before(ya.wait(0.1))
# Repeat 3 times, the 3 frames of the .png
9.times do |i|
  main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, (i % 3) * 104, 0, 104, 192))
  main_t_anim.play_before(ya.wait(0.15))
end
animation_user.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:aqua_ring, :first_use, animation_user, animation_target)
