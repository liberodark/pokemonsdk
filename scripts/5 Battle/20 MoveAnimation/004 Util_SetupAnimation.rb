module Yuki
  module Animation
    module_function

    # Combine multiple animations into one
    # @param animations [Array<TimedAnimation>] animations to combine
    # @param time_global [Float] global time of the animation
    def combine_animation(animations, time_global)
      animation = Yuki::Animation.wait(time_global)
      animations.each { |anim| animation.parallel_add(anim) }
      return animation
    end

    # Combine an animation with a sound
    # @param sound [String] sound to play
    # @param animations [Array<TimedAnimation>] animations to combine
    # @param time_global [Float] global time of the animation
    def combine_animation_with_sound(sound, animations, time_global)
      animation = Yuki::Animation.se_play(sound)
      animation.play_before(combine_animation(animations, time_global))
      return animation
    end

    # Combine multiple animations into one with play_before
    # @param animations [Array<TimedAnimation>] animations to combine in play_before
    def combine_before_animation(animations)
      animation = Yuki::Animation.wait(0)
      animations.each { |anim| animation.play_before(anim) }
      return animation
    end

    # Combine multiple animations into one with play_before with a sound
    # @param sound [String] sound to play
    # @param animations [Array<TimedAnimation>] animations to combine in play_before
    def combine_before_animation_with_sound(sound, animations)
      animation = Yuki::Animation.se_play(sound)
      animations.each { |anim| animation.play_before(anim) }
      return animation
    end
  end
end
