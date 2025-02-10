ya = Yuki::Animation
# VineWhip

animation_user = ya.wait(0.05)
animation_target = ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'vine-whip', :animation], [:set_rect, 0, 0, 200, 200], [:zoom=, 1], [:set_origin, 100, 100])
main_t_anim = ya.resolved
main_t_anim.play_before(ya.move_sprite_position(0, :sprite, :target, :target))
main_t_anim.play_before(ya.se_play('moves/vine_whip'))
main_t_anim.play_before(ya.send_command_to(:sprite, :z=, 1))
8.times do |i|
  7.times do |j|
    main_t_anim.play_before(ya.wait(0.015))
    main_t_anim.play_before(ya.send_command_to(:sprite, :set_rect, 200*j, 200*i, 200, 200))
  end
end
main_t_anim.play_before(ya.wait(0.05))
animation_target.play_before(main_t_anim)
animation_target.play_before(ya.dispose_sprite(:sprite))

Battle::MoveAnimation.register_specific_animation(:vine_whip, :first_use, animation_user, animation_target)