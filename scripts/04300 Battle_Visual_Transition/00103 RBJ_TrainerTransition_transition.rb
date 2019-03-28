module Battle
  class Visual
    class RBJ_TrainerTransition

      private

      # Get the enemy sprites
      # @return [Array<ShaderedSprite>]
      def enemy_sprites
        sprites = []
        $game_temp.vs_type.times do |i|
          sprite = @battle_scene.visual.battler_sprite(1, i)
          sprite&.visible = false
          sprite = @battle_scene.visual.battler_sprite(1, -i - 1)
          sprites << sprite if sprite
        end
        return sprites
      end
    end
  end
end
