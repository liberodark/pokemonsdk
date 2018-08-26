#encoding: utf-8

#noyard
module GamePlay
  class TCard < Base
    TC_Girl = "Trainer_Card_F"
    TC_Boy = "Trainer_Card_M"
    include Text::Util
    def initialize
      super(true)
      @viewport = select_view(view(:main, 10000))
      #@background_main = background(Party_Menu::Background)
      @background = sprite($trainer.playing_girl ? TC_Girl : TC_Boy, 
        32, 24, 1)
      init_text(0, @viewport)
      draw_text
      @counter = 0
    end

    def update
      if Input.trigger?(:B)
        @running = false
      end
      @counter += 1
      if(@counter > 30)
        switch_sprite
        @counter = 0
      end
    end

    def draw_text
      start_time = (Time.new-(Time.new.to_i-$trainer.start_time))
      add_text(16,32,136,16, _get(34,0))
      add_text(16,32,136,16, $trainer.name, 2)
      add_text(16,48,136,16, _get(34,2))
      add_text(16,48,136,16, sprintf("%05d",$trainer.id%100000), 2)
      add_text(16,72,136,16, _get(34,7))
      add_text(16,72,136,16, _parse(34,8, NUM7R => $pokemon_party.money.to_s), 2)
      add_text(16,120,136,16, _get(25,1))
      add_text(16,120,136,16, $trainer.badge_counter.to_s, 2)
      add_text(16,144,224,16, _get(34,10))
      add_text(16,160,224,16, _get(34,14))
      add_text(16,160,224,16, _parse(34,15, 
        /\[VAR NUM4[^\]]*\]/ => start_time.year.to_s,
        NUM2[2] => sprintf("%02d", start_time.day),
        NUM2[1] => sprintf("%02d", start_time.month)),
        2)
      time = $trainer.update_play_time
      hours = time/3600
      minutes = (time-3600*hours)/60
      @txt_dot = add_text(16,144,224,16, sprintf("%02d %s %02d", hours, _get(25,6), minutes), 2)
      @txt_ndot1 = add_text(16,144,224,16, sprintf("%02d", minutes), 2)
      @txt_ndot2 = add_text(16,144,202,16, sprintf("%02d", hours), 2)
      @texts.each { |text| text.set_position(text.x + 32, text.y + 24) }
      switch_sprite
    end

    def switch_sprite
      state = @txt_ndot1.visible
      @txt_ndot1.visible =@txt_ndot2.visible = !state
      @txt_dot.visible = state
    end
  end
end
