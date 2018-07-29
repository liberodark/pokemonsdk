#encoding: utf-8

module GameData
  # Module that helps the game to get text in various langages
  # @author Nuri Yuri
  module Text
    # List of lang id available in the game
    Available_Langs = ["kana","en","fr","it","de","es","ko"]
    @texts = []
    @lang = nil
    # TextDataError constant (informative)
    ::TextDataError = Class.new(RuntimeError)
    module_function
    # load text in the correct lang ($options.language or LANG in game.ini)
    def load
      lang = ($pokemon_party ? $pokemon_party.options.language : get_default_lang)#Kernel.get_string("PokemonSDK","LANG"))
      unless(lang and Available_Langs.include?(lang))
        print("Bad language (#{lang}), Game.ini->PokemonSDK->LANG can only be :\n#{Available_Langs.join(",")}")
        lang=Available_Langs[0]
#        Kernel.set_string("PokemonSDK","LANG",lang)
      end
      @texts=Marshal.load(Zlib::Inflate.inflate(load_data("Data/Text/#{lang}.dat")))
      @lang=lang
    end
    # Return the default game lang
    def get_default_lang
      "fr"
    end
    # Get a text front the text database
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @raise [TextDataError] if the file or the text has not been found
    # @return [String] the text
    def get(file_id,text_id)
      if(file=@texts[file_id])
        if(text=file[text_id])
          return text
        end
        raise TextDataError,"Unable to find text #{text_id} in file #{file_id}."
      else
        raise TextDataError,"File #{file_id} doesn't exist."
      end
    end
    # Get a list of text from the text database
    # @param file_id [Integer] ID of the text file
    # @raise [TextDataError] if the file does not exist
    # @return [Array<String>] the list of text contained in the file.
    def get_file(file_id)
      if(file=@texts[file_id])
        return file
      else
        raise TextDataError,"File #{file_id} doesn't exist."
      end
    end
  end
end
