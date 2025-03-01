ya = Yuki::Animation
# Avalanche
animation_user = ya.wait(0.1)
animation_target = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'avalanche', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1.25], [:set_origin, 52, 110])
main_t_anim = ya.resolved
animation_target.play_before(main_t_anim)
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :target, :target))
main_t_anim.play_before(ya.se_play('moves/avalanche'))
main_t_anim.play_before(ya.wait(0.1))
# Each time, the following frame of the .png is taken
19.times do |i|
    main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192))
    main_t_anim.play_before(ya.wait(0.1))
end
animation_target.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:avalanche, :first_use, animation_user, animation_target)
