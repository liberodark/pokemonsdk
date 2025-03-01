ya = Yuki::Animation
# AcidArmor
animation_target = ya.wait(0.1)
animation_user = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'acid_armor', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132])
main_t_anim = ya.resolved
animation_user.play_before(main_t_anim)
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :user, :user))
main_t_anim.play_before(ya.se_play('moves/acid_armor'))
main_t_anim.play_before(ya.wait(0.1))
# Repeat 2 times, the 4 frames of the .png
8.times do |i|
  main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, (i % 4) * 104, 0, 104, 192))
  main_t_anim.play_before(ya.wait(0.12))
end
animation_user.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:acid_armor, :first_use, animation_user, animation_target)
