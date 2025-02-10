## Module allowing the animation to chose the bank of the user in case of differences
module Yuki
  module Animation
    class UserBankRelativeAnimation < Command
      def initialize
        super
        @bank_animations = []
      end

      def play_before_on_bank(bank, other)
        if @bank_animations[bank]
          @bank_animations[bank].play_before(other)
        else
          @bank_animations[bank] = other
        end
        other.root = root
        return other
      end

      def play_parallel_on_bank(bank, other)
        if @bank_animations[bank]
          @bank_animations[bank].parallel_play(other)
        else
          @bank_animations[bank] = other
        end
        other.root = root
        return other
      end

      def start(begin_offset = 0)
        @parallel_animations.delete_if { |anim| @bank_animations.include?(anim) }
        bank_animation = @bank_animations[resolve(:user).bank]
        bank_animation.resolver = @resolver
        @parallel_animations << bank_animation
        super
      end
    end
  end
end