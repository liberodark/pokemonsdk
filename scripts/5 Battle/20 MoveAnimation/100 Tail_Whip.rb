ya = Yuki::Animation
# Tail Whip

animation_user = ya.wait(0)
following_anim = Yuki::Animation::UserBankRelativeAnimation.new
following_anim.play_before_on_bank(0, ya.ellipse(1.5, :user, 18, 9, turn: 2))
following_anim.play_before_on_bank(1, ya.ellipse(1.5, :user, 11, -5, turn: 2))
animation_user.play_before(following_anim)
animation_target = ya.se_play('moves/tail_whip')

Battle::MoveAnimation.register_specific_animation(:tail_whip, :first_use, animation_user, animation_target)