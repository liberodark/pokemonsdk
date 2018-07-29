#encoding: utf-8

#noyard
module GamePlay
  class Shortcut < Base
    #> Inclusions
    include ::Util::Item
    def initialize
      super
      @items = $bag.get_shortcuts
      @viewport = select_view(view(:main, 10000))
      @back = background("Shortcut")
      @back.x = (320 - @back.bitmap.width) / 2
      @back.y = (240 - @back.bitmap.height) / 2 - 9
      delta_x = @back.bitmap.width / 3 + 1
      delta_y = @back.bitmap.height / 3 + 1
      @item_sprites = Array.new(PFM::Bag::MAX_ShortCut) do |i|
        sprite(@items[i] != 0 ? GameData::Item.icon(@items[i]) : nil,
          @back.x + (i & 0x01 == 1 ? (delta_x * (i & 0x02)) : delta_x) + 1,
          @back.y + (i & 0x01 == 1 ? delta_y : delta_y * i) + 1,
          i, cache_name: :icon, 
          opacity: $bag.has_item?(@items[i]) ? 255 : 96)
      end
    end

    def update
      return unless super
      if Input.trigger?(:B) or Input.trigger?(:Y)
        @running = false
      elsif(Input.trigger?(:UP))
        use(0)
      elsif(Input.trigger?(:DOWN))
        use(2)
      elsif(Input.trigger?(:RIGHT))
        use(3)
      elsif(Input.trigger?(:LEFT))
        use(1)
      end
    end

    def use(index)
      item_id = @items[index]
      return @running = false if item_id == 0 or !$bag.has_item?(item_id)
      util_item_useitem(item_id)
    end
=begin
    def dispose
      @back.dispose
      @item_sprites.each do |i|
        i.dispose
      end
      @viewport.dispose
    end
=end
  end
end
