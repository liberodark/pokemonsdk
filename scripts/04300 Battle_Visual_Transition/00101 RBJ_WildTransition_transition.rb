module Battle
  class Visual
    class RBJ_WildTransition
      # Number of frame to move the sprites
      SPRITE_MOVE_DURATION = 120
      # Number of pixel the sprites moves each frames
      SPRITE_MOVE_PIXEL = 3
      # Set the Transition in Transition mode
      def transition
        Graphics.freeze
        @update_method = :update_transition
        @counter = 0
        @viewport.color.set(0, 0, 0, 0)
        @viewport.sort_z
        @shader = Shader.new(Shader::GeneralColorSprite)
        @shader.set_float_uniform('color', [0, 0, 0, 1])
        load_enemy_sprites
        load_actors_sprites
        Graphics.transition(15)
        @done = false
      end

      private

      # Update the transition animation
      def update_transition
        if @counter < SPRITE_MOVE_DURATION
          @actor_sprites.each { |sprite| sprite.x -= SPRITE_MOVE_PIXEL }
          @enemy_sprites.each { |sprite| sprite.x += SPRITE_MOVE_PIXEL }
        elsif @counter == SPRITE_MOVE_DURATION
          @enemy_sprites.each { |sprite| sprite.shader = nil }
        end
        @counter += 1
        unless @counter < 180
          @battle_scene.visual.unlock
          @done = true
        end
      end

      # Load the enemy sprites
      def load_enemy_sprites
        @enemy_sprites = enemy_sprites
        @enemy_sprites.each do |sprite|
          sprite.shader = @shader
          sprite.x -= SPRITE_MOVE_DURATION * SPRITE_MOVE_PIXEL
        end
      end

      # Get the enemy sprites
      # @return [Array<ShaderedSprite>]
      def enemy_sprites
        sprites = []
        $game_temp.vs_type.times do |i|
          sprite = @battle_scene.visual.battler_sprite(1, i)
          sprites << sprite if sprite
        end
        return sprites
      end

      # Load the actor sprites
      def load_actors_sprites
        @actor_sprites = actor_sprites
        @actor_sprites.each do |sprite|
          sprite.x += SPRITE_MOVE_DURATION * SPRITE_MOVE_PIXEL
        end
      end

      # Get the actor sprites (and hide the mons)
      # @return [Array<ShaderedSprite>]
      def actor_sprites
        sprites = []
        $game_temp.vs_type.times do |i|
          sprite = @battle_scene.visual.battler_sprite(0, i)
          sprite&.visible = false
          sprite = @battle_scene.visual.battler_sprite(0, -i - 1)
          sprites << sprite if sprite
        end
        return sprites
      end
    end
  end
end
