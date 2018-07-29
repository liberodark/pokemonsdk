#encoding: utf-8

# Class that define a shader
class Shader
  # Load a shader data from a file
  # @param filename [String] name of the file in Graphics/Shaders
  # @return [String] the shader string
  def self.load_to_string(filename)
    File.open("graphics/shaders/#{filename.downcase}.txt", "r") do |f|
      return f.read(f.size)
    end
  end
  # General Shader of Sprite that need color mix
  GeneralColorSprite = self.load_to_string("GenColorSprite")
end
