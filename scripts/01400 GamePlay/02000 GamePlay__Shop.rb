#encoding: utf-8

#noyard
module GamePlay
  class Shop < Base
    Selector = "Bag_selector"
    def initialize
      super()
      @viewport = Viewport.create(:main, 1000)
      @index = 0
      #> Fenêtre de l'argent
      @gold_window = ::Game_Window.new(@viewport)
      wb = @gold_window.window_builder
      @gold_window.x = 2
      @gold_window.y = 2
      @gold_window.width = 64 + wb[0]*2
      @gold_window.height = 32 + wb[1]
      @gold_window.windowskin = RPG::Cache.windowskin("Message")
      @gold_window.add_text(0,0,64,16,_get(11, 6))
      @money_text = @gold_window.add_text(0,16,64,16,_parse(11, 9, 
        NUM7R => $pokemon_party.money.to_s), 2)
      #draw_gold_window
      #> Fenêtre des objets
      @item_window = ::Game_Window.new(@viewport)
      @item_window.y = 2
      @item_window.width = 150 + wb[0]*2
      @item_window.x = 320 - @item_window.width - 2
      @item_window.height = 128 + wb[1]
      @item_window.windowskin = @gold_window.windowskin
      #> Selecteur
      @selector = ::Sprite.new(@viewport)
      @selector.x = @item_window.x + wb[0]
      @selector.z = 2
      @selector.bitmap = RPG::Cache.interface(Selector)
      @selector.src_rect.height = @selector.bitmap.height / 2
      #>Interface de description
      @descr_window = ::Game_Window.new(@viewport)
      @descr_window.x = 2
      @descr_window.width = 316
      @descr_window.height = 48 + wb[1]
      @descr_window.windowskin = @gold_window.windowskin
      @descr_window.y = 240 - @descr_window.height - 2
      @descr_text = @descr_window.add_text(48, 0, 240, 16, " ")
      @icon_sprite = Sprite.new(@viewport).
        set_position(@descr_window.ox + @descr_window.x + 8, @descr_window.oy + @descr_window.y + 8)
      #>Delta y pour le selecteur
      @delta_y = 2 + wb[5]
      i = 0
      @goods = Array.new($game_temp.shop_goods.size) { |i| $game_temp.shop_goods[i][1] }
      @item_names = Array.new(@goods.size) { |i| ::GameData::Item.name(@goods[i]) }
      @item_prices = Array.new(@goods.size) { |i| _parse(22,159, NUM7R => ::GameData::Item.price(@goods[i]).to_s) }
      @price_text = Array.new
      @name_text = Array.new(11) do |cnt|
        @price_text << @item_window.add_text(6, cnt*16, 140, 16," ", 2)
        @item_window.add_text(6, cnt*16, 142, 16," ")
      end
      draw_item_list
      draw_descr
      @mode = 0
    end

    def main_begin
      @update_spritemap = @__last_scene.class == ::Scene_Map
      super
    end

    def main_end
      super
      $game_temp.last_menu_index = @index
    end

    def update
      @__last_scene.sprite_set_update if @update_spritemap
      super
      return if $game_temp.message_window_showing
      draw = true
      if Input.repeat?(:UP)
        @index -= 1
        @index = @goods.size if @index < 0
      elsif Input.repeat?(:DOWN)
        @index += 1
        @index = 0 if @index > @goods.size
      elsif(Input.trigger?(:A))
        if(@index < @goods.size)
          buy_item(@goods[@index])
        else
          return @running = false
        end
      elsif(Input.trigger?(:B))
        return @running = false
      else
        draw = false
      end
      if draw
        draw_item_list
        draw_descr
      end
    end

    def buy_item(item_id)
      price = ::GameData::Item.price(item_id)
      if(price == 0 or price > $pokemon_party.money)
        display_message(_parse(11, 24))
        return
      else
        max_amount = $pokemon_party.money/price
        if (max = GameData::Bag::MaxItem) > 0
          max = max - $bag.item_quantity(item_id)
          if max <= 0
            display_message(_parse(11, 31))
            return
          end
          max_amount = max if max < max_amount
        end
        $game_temp.num_input_variable_id = ::Yuki::Var::EnteredNumber
        $game_temp.num_input_digits_max = (max_amount).to_s.size
        $game_temp.num_input_start = max_amount
        $game_temp.shop_calling = price
        display_message(_parse(11,23, ITEM2[0] => ::GameData::Item.name(item_id)))
        value = $game_variables[::Yuki::Var::EnteredNumber]
        if(value > 0)
          c = display_message(_parse(11,25, ITEM2[0] => ::GameData::Item.name(item_id),
          NUM2[1] => value.to_s, NUM7R => (value * price).to_s), 1,
          _get(11,27), _get(11,28))
          return if(c != 0)
        else
          return
        end
        $bag.add_item(item_id, value)
        $pokemon_party.lose_money(value * price)
        draw_gold_window
        display_message(_get(11,29))
        if(item_id == 4 && value >= 10)
          display_message(_get(11,32))
          $bag.add_item(12, 1)
        end
        #> Jouer le bruit du shop
      end
    end

    def draw_descr
      if @index < @goods.size
        item_id = @goods[@index]
        @icon_sprite.bitmap = RPG::Cache.icon(::GameData::Item.icon(item_id))
        @descr_text.multiline_text = GameData::Item.descr(item_id)
      else
        @descr_text.text = " "
        @icon_sprite.bitmap = nil
      end
    end

    def draw_item_list
      size = @goods.size
      #>Calibrage de l'index initial
      if(@index>3)
        if(size>8 and @index>(size-4))
          ini_index=size-7
        else
          ini_index=@index-4
        end
      else
        ini_index=0
      end
      cnt = -1
      #>Dessin des textes
      ini_index.step(ini_index+10) do |i|
        cnt+=1
        @selector.y = @delta_y + cnt*16 if(i==@index)
        @price_text[cnt].visible = @name_text[cnt].visible = (i < size)
        if(i>=size)
          if i == size
            @name_text[cnt].text = _get(22,7)
            @name_text[cnt].visible = true
          end
          next
        end
        @name_text[cnt].text = @item_names[i]
        @price_text[cnt].text = @item_prices[i]
      end
    end

    def draw_gold_window
      @money_text.text = _parse(11, 9, 
        NUM7R => $pokemon_party.money.to_s)
    end

    def dispose
      super
=begin
      @gold_window.dispose
      @item_window.dispose
      @descr_window.dispose
      @selector.dispose
      @viewport.dispose
=end
    end
  end
end
