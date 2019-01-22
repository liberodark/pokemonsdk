#encoding: utf-8

module GamePlay
  class Sumary
    # Show the Informations of the Pokémon in the Sumary interface
    class C < UI::SpriteStack
      include UI
      # Access to the skill related stack
      # @return Hash
      attr_reader :skill_stack
      def initialize(viewport, x = 0, y = 0, default_cache: :interface)
        super
        texts = _get_file(27)
        add_text(4,0,95,20, _ext(9000, 42), color: 8)
        add_text(198,42,95,20, _ext(9000, 43), color: 8)
        add_text(19, 23, 66, 19, :given_name, type: SymText, color: 8)
        add_text(19, 39, 66, 19, :level_text2, type: SymText)
        push(85, 27, nil, type: GenderSprite)
        add_text(4, 55, 95, 18, _get(23,7), color: 8) #Objet
        add_text(4, 71, 95, 16, :item_name, type: SymText)
        4.times do |i|
          push_sprite(Skill.new(viewport, i, -157, 22))
        end
        push(168 + 16, 78 + 16, nil, type: PokemonIconSprite).mirror = true
        push(205, 92, nil, type: Type1Sprite)
        push(239, 92, nil, type: Type2Sprite)
        add_text(173,110,68,16,texts[36], color: 8)
        add_text(173,127,68,16,texts[37], color: 8)
        add_text(173,143,68,16,texts[39], color: 8)
        @skill_stack = {
          category: CategorySprite.new(viewport).set_position(248, 112),
          power: SymText.new(0, viewport, 243, 127, 42, 16, :power_text, 1),
          accuracy: SymText.new(0, viewport, 243, 143, 42, 16, :accuracy_text, 1),
          descr: SymMultilineText.new(0, viewport, 132, 159, 151, 16, :description)
        }
      end
      # Change the Pokemon shown
      # @param v [PFM::Pokemon]
      def data=(v)
        return self.visible = false unless v
        self.visible = true
        super
      end
      # Change the visibility of the Informations
      # @param v [Boolean]
      def visible=(v)
        super
        @skill_stack.each_value { |sprite| sprite.visible = v }
      end
    end
  end
end
