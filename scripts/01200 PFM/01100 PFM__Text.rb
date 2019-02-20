#encoding: utf-8

module PFM
  # The text parser of PSDK (retreive text from GameData::Text)
  # @author Nuri Yuri
  module Text
    @variables = {}
    @numbrach_state = 0
    # Pokemon Nickname var catcher
    PKNICK = ["[VAR PKNICK(0000)]","[VAR PKNICK(0001)]","[VAR PKNICK(0002)]"]
    # Pokemon name var catcher
    PKNAME = ["[VAR PKNAME(0000)]","[VAR PKNAME(0001)]","[VAR PKNAME(0002)]"]
    # Trainer name var catcher
    TRNAME = ["[VAR TRNAME(0000)]","[VAR TRNAME(0001)]"]
    # Item var catcher
    ITEM2 = ["[VAR ITEM2(0000)]","[VAR ITEM2(0001)]","[VAR ITEM2(0002)]"]
    # Move var catcher
    MOVE = ["[VAR MOVE(0000)]","[VAR MOVE(0001)]","[VAR MOVE(0002)]"]
    # Number var catcher
    NUMB = [nil.to_s,"[VAR NUM1(0000)]","[VAR NUM1(0001)]"]
    # Number 3 var catcher
    NUM3 = ['[VAR NUM3(0000)]', '[VAR NUM3(0001)]', '[VAR NUM3(0002)]']
    # Number 2 var catcher
    NUM2 = ['[VAR NUM2(0000)]', '[VAR NUM2(0001)]', '[VAR NUM2(0002)]', '[VAR NUM2(0003)]']
    # Number 7 var catcher regexp
    NUM7R = /\[VAR NUM7[^\]]*\]/
    # Number x var catcher regexp
    NUMXR = /\[VAR NUM.[^\]]*\]/
    # Berry var catcher
    BERRY = ["","","","","","","","[VAR BERRY(0007)]"]
    # Color var catcher
    COLOR = ["[VAR COLOR(0000)]","[VAR COLOR(0001)]","[VAR COLOR(0002)]","[VAR COLOR(0003)]"]
    # Location var catcher
    LOCATION = ["[VAR LOCATION(0000)]","[VAR LOCATION(0001)]","[VAR LOCATION(0002)]","[VAR LOCATION(0003)]","[VAR LOCATION(0004)]"]
    # Ability var catcher
    ABILITY = ["[VAR ABILITY(0002)]","[VAR ABILITY(0001)]","[VAR ABILITY(0002)]"]
    # Kaphotics decoded var clean regexp
    KAPHOTICS_Clean = /\[VAR [^\]]+\]/#/\[VAR .[A-Z\,\(\)a-z0-9]+\]/
    # Nummeric branch regexp catcher
    NUMBRNCH_Reg = /\[VAR NUMBRNCH\(....,....\)\][^ ]+/
    # Gender branch regexp catcher
    GENDBR_Reg = /\[VAR GENDBR\(....,....\)\].*+/
    # Bell detector
    BELL_Reg = /\[VAR BE05\(([0-9]+)\)\]/ # A implémenter !
    # Empty string (remove stuff)
    S_Empty = nil.to_s
    # Non breaking space "!" detector
    NBSP_B = / !/
    # Non breaking space "!" remplacement
    NBSP_R = " !"
    # Automatic replacement of ... with the correct char
    Dot = ["...","…"]
    # Automatic replacement of the $ with a non breaking space $
    Money = [" $"," $"]
    @plural = false
    module_function
    # Define generic constants adder to an object (Get var catcher easier)
    # @param obj [Class] the object that will receive constants
    def define_const(obj)
      obj.const_set(:PKNICK, PKNICK)
      obj.const_set(:PKNAME, PKNAME)
      obj.const_set(:TRNAME, TRNAME)
      obj.const_set(:ITEM2, ITEM2)
      obj.const_set(:MOVE, MOVE)
      obj.const_set(:NUMB, NUMB)
      obj.const_set(:NUM3, NUM3)
      obj.const_set(:NUM2, NUM2)
      obj.const_set(:COLOR, COLOR)
      obj.const_set(:LOCATION, LOCATION)
      obj.const_set(:ABILITY, ABILITY)
      obj.const_set(:NUM7R, NUM7R)
      obj.const_set(:NUMXR, NUMXR)
    end
    # Parse a text from the text database with specific informations
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @param additionnal_var [nil, Hash{String => String}] additional remplacements in the text
    # @return [String] the text parsed and ready to be displayed
    def parse(file_id, text_id, additionnal_var = nil)
      parse_with_pokemon(file_id, text_id, nil, additionnal_var)
    end
    # Parse a text from the text database with specific informations and a pokemon
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @param pokemon [PFM::Pokemon] pokemon that will introduce an offset on text_id (its name is also used)
    # @param additionnal_var [nil, Hash{String => String}] additional remplacements in the text
    # @return [String] the text parsed and ready to be displayed
    def parse_with_pokemon(file_id, text_id, pokemon, additionnal_var = nil)
      if(pokemon and pokemon.position<0)
        text_id += ($game_temp.trainer_battle ? 2 : 1)
      end
      text = ::GameData::Text.get(file_id, text_id).clone
      #>Remplacement des variables
      if(additionnal_var)
        additionnal_var.each { |expr,value| text.gsub!(expr,value) }
      end
      @variables.each { |expr,value| text.gsub!(expr,value) }
      text.gsub!(PKNICK[0], pokemon.given_name) if pokemon
      #>Détection des numbrnch
      s = nil
      text.gsub!(NUMBRNCH_Reg) do |s|
        quant = s.split(',')[1].to_i(16)
        ret = s.split(']')[1]
        if(@plural)
          beg = quant&0xFF
          len = quant>>8
          _end = beg + len
          len2 = ret.size-_end
        else
          beg = 0
          len = quant&0xFF
          _end = len + (quant>>8)
          len2 = ret.size-_end
        end
        ret[beg,len]+ret[_end,len2]
      end
      text.gsub!(GENDBR_Reg) do |s|
        quant = s.split(',')[1].to_i(16)
        ret = s.split(']')[1]
        if($trainer.playing_girl)
          beg = quant&0xFF
          len = quant>>8
          _end = beg + len
          len2 = ret.size-_end
        else
          beg = 0
          len = quant&0xFF
          _end = len + (quant>>8)
          len2 = ret.size-_end
        end
        ret[beg,len]+ret[_end,len2]
      end
      text.gsub!(KAPHOTICS_Clean,S_Empty)
      text.gsub!(NBSP_B, NBSP_R)
      return text
    end
    # Parse a text from the text database with specific informations and two Pokemon
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @param pokemon [PFM::Pokemon] pokemon that will introduce an offset on text_id (its name is also used)
    # @param pokemon2 [PFM::Pokemon] second pokemon that will introduce an offset on text_id (its name is also used)
    # @param additionnal_var [nil, Hash{String => String}] additional remplacements in the text
    # @return [String] the text parsed and ready to be displayed
    def parse_with_pokemons(file_id, text_id, pokemon, pokemon2, additionnal_var = nil)
      if(pokemon.position>=0)
        text_id += ($game_temp.trainer_battle ? 2 : 1) if(pokemon2.position < 0)
      else
        text_id += ($game_temp.trainer_battle ? 5 : 3)
        text_id += 1 if(pokemon2.position < 0)
      end
      text = ::GameData::Text.get(file_id, text_id).clone
      #>Remplacement des variables
      if(additionnal_var)
        additionnal_var.each { |expr,value| text.gsub!(expr,value) }
      end
      @variables.each { |expr,value| text.gsub!(expr,value) }
      text.gsub!(PKNICK[0], pokemon.given_name) if pokemon
      text.gsub!(PKNICK[1], pokemon2.given_name) if pokemon2
      #>Détection des numbrnch
      s = nil
      text.gsub!(NUMBRNCH_Reg) do |s|
        quant = s.split(',')[1].to_i(16)
        ret = s.split(']')[1]
        if(@plural)
          beg = quant&0xFF
          len = quant>>8
          _end = beg + len
          len2 = ret.size-_end
        else
          beg = 0
          len = quant&0xFF
          _end = len + (quant>>8)
          len2 = ret.size-_end
        end
        ret[beg,len]+ret[_end,len2]
      end
      text.gsub!(KAPHOTICS_Clean,S_Empty)
      text.gsub!(NBSP_B, NBSP_R)
      return text
    end
    # Define an automatic var catcher with its value
    # @param expr [String, Regexp] the var catcher that is replaced by the value
    # @param value [String] the value that replace the expr
    def set_variable(expr, value)
      @variables[expr] = value.to_s
        .force_encoding(Encoding::UTF_8) #£EncodingPatch
    end
    # Remove an automatic var catcher with its value
    # @param expr [String, Regexp] the var catcher that is replaced by a value
    def unset_variable(expr)
      @variables.delete(expr)
    end
    # Remove every automatic var catcher defined
    def reset_variables
      @variables.clear
    end
    # Set the numbranches to plural state
    def set_plural(v = true)
      @plural = v
    end
    # The \\ temporary replacement
    S_000 = ::Window_Message::S_000
    # Parse a string for a message
    # @param text [String] the message
    # @return [String] the parsed message
    def parse_string_for_messages(text)
      return text if text.empty? # or text.frozen?
      # Detect dialog
      text = detect_dialog(text).dup
      # Gsub text
      text.gsub!(/\\\\/,S_000)
      text.gsub!(/\\[Vv]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
      text.gsub!(/\\[Nn]\[([0-9]+)\]/) { $game_actors[$1.to_i] != nil ? $game_actors[$1.to_i].name : nil.to_s }
      text.gsub!(/\\[Pp]\[([0-9]+)\]/) { $actors[$1.to_i-1]  ? $actors[$1.to_i-1].name : nil.to_s }
      text.gsub!(/\\[Kk]\[([^\]]+)\]/) { get_key_name($1)}
      text.gsub!("\\E") { $game_switches[Yuki::Sw::Gender] ? "e" : nil }
      text.gsub!(/\\[Ff]\[([A-Za-z0-9_çëïéèàêûù§]+)\]/) { $1.split("§")[$game_switches[Yuki::Sw::Gender] ? 0 : 1] }
      text.gsub!(/\\t\[([0-9]+), *([0-9]+)\]/) { ::PFM::Text.parse($1.to_i, $2.to_i) }
      #text.gsub!(NBSP_B, NBSP_R)
      text.gsub!(*Dot)
      text.gsub!(*Money)
      @variables.each { |expr,value| text.gsub!(expr,value) }
      return text
    end
    # Detect a dialog text from message and return it instead of text
    # @param text [String]
    def detect_dialog(text)
      if (match = text.match(/^([0-9]+),( |)([0-9]+)/))
        text = GameData::Text.get_dialog_message(match[1].to_i, match[3].to_i)
      end
      return text
    end
    # The InGame key name to their key value association
    GameKeys = { 0 => "KeyError", "a" => :A, "b" => :B, "x" => :X, "y" => :Y, 
      "l" => :L, "r" => :R, "l2" => :L2, "r2" => :R2, "select" => :SELECT, "start" => :START,
      "l3" => :L3, "r3" => :R3, "down" => :DOWN, "left" => :LEFT, 
      "right" => :RIGHT, "up" => :UP, "home" => :HOME}
    # Return the real keyboard key name
    # @param name [String] the InGame key name
    # @return [String] the keyboard key name
    def get_key_name(name)
      key_id = GameKeys[name.downcase]
      return GameKeys[0] unless key_id
      key_value = Input::Keys[key_id][0]
      return "J#{-(key_value + 1) / 32 + 1}K#{(-key_value - 1)% 32}" if(key_value < 0)
      keybd = Input::Keyboard
      keybd.constants.each do |key_name|
        if keybd.const_get(key_name) == key_value
          return key_name.to_s
        end
      end
      return GameKeys[0]
    end

    # Set the Pokemon Name variable
    # @param value [String, PFM::Pokemon]
    # @param index [Integer] index of the pkname variable
    def set_pkname(value, index = 0)
      value = value.name if value.is_a?(PFM::Pokemon)
      set_variable(PKNAME[index].to_s, value.to_s)
    end

    # Set the Pokemon Nickname variable
    # @param value [String, PFM::Pokemon]
    # @param index [Integer] index of the pknick variable
    def set_pknick(value, index = 0)
      value = value.given_name if value.is_a?(PFM::Pokemon)
      set_variable(PKNICK[index].to_s, value.to_s)
    end

    # Set the item name variable
    # @param value [String, Symbol, Integer]
    # @param index [Integer] index of the item variable
    def set_item_name(value, index = 0)
      value = GameData::Item.get_id(item_id) if value.is_a?(Symbol)
      value = GameData::Item.name(value) if value.is_a?(Integer)
      set_variable(ITEM2[index].to_s, value.to_s)
    end

    # Set the move name variable
    # @param value [String, Symbol, Integer]
    # @param index [Integer] index of the move variable
    def set_move_name(value, index = 0)
      value = GameData::Skill.get_id(item_id) if value.is_a?(Symbol)
      value = GameData::Skill.name(value) if value.is_a?(Integer)
      set_variable(MOVE[index].to_s, value.to_s)
    end

    # Set the ability name variable
    # @param value [String, Symbol, Integer, PFM::Pokemon]
    # @param index [Integer] index of the move variable
    def set_ability_name(value, index = 0)
      value = GameData::Abilities.find_using_symbol(item_id) if value.is_a?(Symbol)
      value = GameData::Abilities.name(value) if value.is_a?(Integer)
      value = value.ability_name if value.is_a?(PFM::Pokemon)
      set_variable(ABILITY[index].to_s, value.to_s)
    end

    # Set the number1 variable
    # @param value [Integer, String]
    # @param index [Integer] index of the number1 variable
    def set_num1(value, index = 1)
      set_variable(NUMB[index].to_s, value.to_s)
    end

    # Set the number2 variable
    # @param value [Integer, String]
    # @param index [Integer] index of the number1 variable
    def set_num2(value, index = 0)
      set_variable(NUM2[index].to_s, value.to_s)
    end

    # Set the number2 variable
    # @param value [Integer, String]
    # @param index [Integer] index of the number1 variable
    def set_num3(value, index = 0)
      set_variable(NUM2[index].to_s, value.to_s)
    end
  end
end
