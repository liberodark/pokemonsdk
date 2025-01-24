module Fake3DCreateSpriteFallback
  def update_internal
    is_fake_3d_context = $scene.is_a?(Battle::Scene) && $scene.visual.is_a?(Battle::Visual3D) && @type == Sprite
    return super unless is_fake_3d_context
    @type = UI::Sprite3D
    super
    sprite = @resolver.receiver[@name]
    $scene.visual.sprites3D.append(sprite)
  end
end

Yuki::Animation::SpriteCreationCommand.prepend(Fake3DCreateSpriteFallback)