#encoding: utf-8

#noyard
module GamePlay
  class Hatch < Base
    def initialize(pkmn, forced = false)
      super()
      @pokemon = pkmn
      @state = 0
    end

    def update
      super
      return if $game_temp.message_window_showing
      if(@state != 0)
        @running = false
      else
        display_message(_parse(36,38, PKNAME[0] => @pokemon.name))
        @state = 1
      end
    end

    def dispose
      super
    end
  end
end
