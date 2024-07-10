class Shader
  module CreatureShaderLoader
    # Load the shader when the Creature gets assigned
    # @param creature [PFM::Pokemon]
    def load_shader(creature)
      shader_id = find_shader_id(creature)
      if @__csl_shader_id != shader_id
        self.shader = Shader.create(shader_id)
        log_debug("Loaded shader #{shader_id} for #{self}")
      end
      @__csl_shader_id = shader_id
      load_shader_properties(creature)
    end

    # Load the shader properties (based on @__csl_shader_id and creature)
    # @param creature [PFM::Pokemon]
    def load_shader_properties(creature)
      # Nothing by default
      # TODO: Add Spinda properties
    end

    # Get the ID of the shader to load
    # @param creature [PFM::Pokemon]
    # @return [Symbol]
    def find_shader_id(creature)
      # Monkey patch this function to change the shader id based on the creature
      # TODO: add Spinda shader
      return :color_shader
    end
  end

  module CreatureShaderForCreatureFaceSpriteHelper
    include CreatureShaderLoader

    private

    # Load the Sprite bitmap
    # @param creature [PFM::Pokemon]
    # @return [Texture]
    def load_bitmap(creature)
      texture = super(creature)
      load_shader(creature)
      return texture
    end
  end

  UI::PokemonFaceSprite.prepend(CreatureShaderForCreatureFaceSpriteHelper)
end