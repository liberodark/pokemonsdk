#encoding: utf-8

module PFM
  class Pokemon
    # Return the icon of the Pokemon
    # @return [Bitmap]
    def icon
      if @step_remaining>0
        str=sprintf("egg_%03d",@id)
        return RPG::Cache.b_icon(str) if RPG::Cache.b_icon_exist?(str)
        return RPG::Cache.b_icon("egg")
      end
      if(@form>0)
        str=sprintf("%03d_%02d",@id,@form)
        return RPG::Cache.b_icon(str) if RPG::Cache.b_icon_exist?(str)
      end
      return RPG::Cache.b_icon(sprintf("%03d",@id))
    end
    # Return the cry file name of the Pokemon
    # @return [String]
    def cry
      return nil.to_s if @step_remaining>0
      return sprintf("Audio/SE/Cries/%03dCry.wav",@id)
    end
    # Return the front battler of the Pokemon
    # @return [Bitmap]
    def battler_face
      if @step_remaining>0
        str=sprintf("egg_%03d",@id)
        return RPG::Cache.poke_front(str) if(RPG::Cache.poke_front_exist?(str))
        return RPG::Cache.poke_front("egg")
      end
      hue=@shiny ? 1 : 0
      if(@gender==2)
        if(@form>0)
          str=sprintf("%03df_%02d",@id,@form)
          return RPG::Cache.poke_front(str,hue) if RPG::Cache.poke_front_exist?(str,hue)
        end
        str=sprintf("%03df",@id)
        return RPG::Cache.poke_front(str,hue) if RPG::Cache.poke_front_exist?(str,hue)
      end
      if(@form>0)
        str=sprintf("%03d_%02d",@id,@form)
        return RPG::Cache.poke_front(str,hue) if RPG::Cache.poke_front_exist?(str,hue)
      end
      str=sprintf("%03d",@id)
      return RPG::Cache.poke_front(str,hue)
    end
    # Return the back battle of the Pokemon
    # @return [Bitmap]
    def battler_back
      if @step_remaining>0
        str=sprintf("egg_%03d",@id)
        return RPG::Cache.poke_back(str) if(RPG::Cache.poke_back_exist?(str))
        return RPG::Cache.poke_back("egg")
      end
      hue=@shiny ? 1 : 0
      if(@gender==2)
        if(@form>0)
          str=sprintf("%03df_%02d",@id,@form)
          return RPG::Cache.poke_back(str,hue) if RPG::Cache.poke_back_exist?(str,hue)
        end
        str=sprintf("%03df",@id)
        return RPG::Cache.poke_back(str,hue) if RPG::Cache.poke_back_exist?(str,hue)
      end
      if(@form>0)
        str=sprintf("%03d_%02d",@id,@form)
        return RPG::Cache.poke_back(str,hue) if RPG::Cache.poke_back_exist?(str,hue)
      end
      str=sprintf("%03d",@id)
      return RPG::Cache.poke_back(str,hue)
    end
    # Return the GifReader face of the Pokemon
    # @return [::Yuki::GifReader, nil]
    def gif_face
      if @step_remaining>0
        return nil
      end
      hue = @shiny ? "Shiny" : ""
      if(@gender == 2)
        if(@form > 0)
          str = sprintf("Graphics/Pokedex/PokeFront%s/%03df_%02d.gif", hue, @id , @form)
          return ::Yuki::GifReader.new(str) if File.exist?(str)
        end
        str = sprintf("Graphics/Pokedex/PokeFront%s/%03df.gif", hue, @id)
        return ::Yuki::GifReader.new(str) if File.exist?(str)
      end
      if(@form > 0)
        str = sprintf("Graphics/Pokedex/PokeFront%s/%03d_%02d.gif", hue, @id, @form)
        return ::Yuki::GifReader.new(str) if File.exist?(str)
      end
      str = sprintf("Graphics/Pokedex/PokeFront%s/%03d.gif", hue, @id)
      return ::Yuki::GifReader.new(str) if File.exist?(str)
      return nil
    end
    # Return the GifReader back of the Pokemon
    # @return [::Yuki::GifReader, nil]
    def gif_back
      if @step_remaining>0
        return nil
      end
      hue = @shiny ? "Shiny" : ""
      if(@gender == 2)
        if(@form > 0)
          str = sprintf("Graphics/Pokedex/PokeBack%s/%03df_%02d.gif", hue, @id , @form)
          return ::Yuki::GifReader.new(str) if File.exist?(str)
        end
        str = sprintf("Graphics/Pokedex/PokeBack%s/%03df.gif", hue, @id)
        return ::Yuki::GifReader.new(str) if File.exist?(str)
      end
      if(@form > 0)
        str = sprintf("Graphics/Pokedex/PokeBack%s/%03d_%02d.gif", hue, @id, @form)
        return ::Yuki::GifReader.new(str) if File.exist?(str)
      end
      str = sprintf("Graphics/Pokedex/PokeBack%s/%03d.gif", hue, @id)
      return ::Yuki::GifReader.new(str) if File.exist?(str)
      return nil
    end
    # Return the character name of the Pokemon
    # @return [String]
    def character_name
      unless @character
        character = nil
        if(@gender==2)
          character = sprintf("%03df%s_%d",@id,@shiny ? "s" : nil,@form)
          character = nil unless RPG::Cache.character_exist?(character)
        end
        unless character
          character = sprintf("%03d%s_%d",@id,@shiny ? "s" : nil,@form)
          unless RPG::Cache.character_exist?(character)
            character = sprintf("%03d%s_0",@id,@shiny ? "s" : nil)
            character = sprintf("%03d_0",@id) unless RPG::Cache.character_exist?(character)
          end
        end
        @character = character
      end
      return @character
    end
  end
end
