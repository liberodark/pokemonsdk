module GamePlay
    class Language_Choice < BaseCleanUpdate

        ANIME_CHANGE = true
        ANIME_FRAMES = 10

        LANGUAGE_CHOICE_LIST = PSDK_CONFIG.choosable_language_code
        DEFAULT_GAME_LANGUAGE = PSDK_CONFIG.default_language_code
       
        def initialize
            super()
            @running = true
            @index = LANGUAGE_CHOICE_LIST.find_index(DEFAULT_GAME_LANGUAGE)
            @counter = 0
            create_graphics
        end

        def create_graphics
            create_viewport
            @stack = UI::SpriteStack.new(@viewport)
            @frame = @stack.add_sprite(0,0,"language/frame")

            @flag_left = @stack.add_sprite(-76,85,nil)
            @flag_left.zoom = 0.9
            @flag_left.opacity = 192
            
            @flag_center = @stack.add_sprite(91,81,nil)
            @flag_center.opacity = 255

            @flag_right = @stack.add_sprite(258,85,nil)
            @flag_right.opacity = 192

            @cursor = @stack.add_sprite(91-4,81-4,"language/cursors",rect:[0,88,146,88] )

            @base_ui = UI::GenericBase.new(@viewport, hide_background_and_button: true)

            update_index
        end

        def update_graphics
            @base_ui.update_background_animation
            @counter += 1
            if @counter >= 60
                @counter = 0
            elsif @counter >= 30   
                @cursor.set_rect(0,0,146,88)
            else
                @cursor.set_rect(0,88,146,88)
            end
        end

        def update_inputs
            if Input.trigger?(:RIGHT)
                @index = @index != 0 ? @index - 1 : LANGUAGE_CHOICE_LIST.size - 1 
                if ANIME_CHANGE == true
                    move(false)
                end
                update_index
            end

            if Input.trigger?(:LEFT)
                @index = @index != LANGUAGE_CHOICE_LIST.size - 1 ? @index + 1 : 0
                if ANIME_CHANGE == true
                    move(true)
                end
                update_index
            end

            if Input.trigger?(:C)
                @running = false
                $pokemon_party = PFM::Pokemon_Party.new(false, LANGUAGE_CHOICE_LIST[@index])
            end
        end

        def update_index
            @flag_left.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index != 0 ? @index - 1 : LANGUAGE_CHOICE_LIST.size - 1]}", :interface)
            @flag_center.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index]}", :interface)
            @flag_right.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index != LANGUAGE_CHOICE_LIST.size-1 ? @index + 1 : 0 ]}", :interface)
        end

        def move(left)
            @cursor.visible = false
            @flag_center.zoom = 0.9
            @flag_center.x = 85
            @flag_center.opacity = 192
            tmp = nil
            if left == true
                tmp = @stack.add_sprite(@flag_right.x + @flag_right. width + 37, 85,nil)
                tmp.opacity = 192
                tmp.zoom = 0.9
                if @index == LANGUAGE_CHOICE_LIST.size - 2
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[0]}", :interface)
                elsif @index == LANGUAGE_CHOICE_LIST.size - 1
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[1]}", :interface)
                else
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index - 2]}", :interface)
                end
                for i in 1..ANIME_FRAMES
                    @flag_center.x -= 167/ANIME_FRAMES
                    @flag_left.x -= 167/ANIME_FRAMES
                    @flag_right.x -= 167/ANIME_FRAMES
                    tmp.x -= 167/ANIME_FRAMES
                    Graphics.update
                end
            else
                tmp = @stack.add_sprite(@flag_left.x - @flag_left. width - 37, 85,nil)
                tmp.opacity = 192
                tmp.zoom = 0.9
                if @index == 0
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[LANGUAGE_CHOICE_LIST.size - 2]}", :interface)
                elsif @index == 1
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[LANGUAGE_CHOICE_LIST.size - 1]}", :interface)
                else
                    tmp.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index + 2]}", :interface)
                end
                for i in 1..ANIME_FRAMES
                    @flag_center.x += 167/ANIME_FRAMES
                    @flag_left.x += 167/ANIME_FRAMES
                    @flag_right.x += 167/ANIME_FRAMES
                    tmp.x -= 167/ANIME_FRAMES
                    Graphics.update
                end
            end
            @flag_left.x = -76
            @flag_left.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index != 0 ? @index - 1 : LANGUAGE_CHOICE_LIST.size - 1]}", :interface)
            @flag_center.x = 91
            @flag_center.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index]}", :interface)
            @flag_center.opacity = 255
            @flag_center.y = 81
            @flag_center.zoom = 1.0
            @flag_right.x = 258
            @flag_right.set_bitmap("language/flags/flag_#{LANGUAGE_CHOICE_LIST[@index != LANGUAGE_CHOICE_LIST.size-1 ? @index + 1 : 0 ]}", :interface)
            @cursor.visible = true
            tmp.dispose
        end
    end
end