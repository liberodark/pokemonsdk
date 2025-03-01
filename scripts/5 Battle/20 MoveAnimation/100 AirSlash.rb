ya = Yuki::Animation
# AirSlash
animation_user = ya.wait(0.1)
animation_target = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'air_slash', :animation], [:set_rect, 0, 0, 208, 192], [:zoom=, 0.75], [:set_origin, 104, 132])
main_t_anim = ya.resolved
animation_target.play_before(main_t_anim)
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :target, :target))
main_t_anim.play_before(ya.se_play('moves/air_slash'))
main_t_anim.play_before(ya.wait(0.1))
# Each time, the following frame of the .png is taken
7.times do |i|
    main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, i * 208, 0, 208, 192))
    main_t_anim.play_before(ya.wait(0.055))
end
animation_target.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:air_slash, :first_use, animation_user, animation_target)
