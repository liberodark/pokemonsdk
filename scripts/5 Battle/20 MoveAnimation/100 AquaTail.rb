ya = Yuki::Animation
# AquaTail
animation_user = ya.wait(0.1)
animation_target = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'aqua_tail', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132])
main_t_anim = ya.resolved
animation_target.play_before(main_t_anim)
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :target, :target))
main_t_anim.play_before(ya.se_play('moves/aqua_tail'))
main_t_anim.play_before(ya.wait(0.1))
# Each time, the following frame of the .png is taken (user side)
3.times do |i|
    main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192))
    main_t_anim.play_before(ya.wait(0.065))
end
# Each time, the following frame of the .png is taken (ennemy side)
4.times do |i|
    main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, 312 + (i * 104), 0, 104, 192))
    main_t_anim.play_before(ya.wait(0.075))
end
animation_target.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:aqua_tail, :first_use, animation_user, animation_target)
