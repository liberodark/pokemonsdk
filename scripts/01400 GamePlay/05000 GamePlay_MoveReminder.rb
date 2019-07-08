module GamePlay

	class Move_Reminder < Base
	
	# Définition des constantes
	BACKGROUND = "MR_UI"
	CURSOR = "ball_selec"
	# @pokemon : Le Pokémon qui doit apprendre une capacité
	# @mode : Implémentation des modes 6G (attaques par reproduction) et 7G (attaques de plus haut niveau)
	
		def initialize (pokemon, mode = 0)
			super
			@index = 0
			@pokemon = pokemon
			@mode = mode
			@move_set = define_move_set
			@viewport = Viewport.create(:main, 1000)
			@background = ::UI::SpriteStack.new(@viewport)
			@background.push(0,13, RPG::Cache.interface(BACKGROUND))
			@texts = Array.new
			@sprites = Array.new
			@summary = Array.new
			@cursor = Sprite.new(@viewport)
			@cursor.set_bitmap(RPG::Cache.interface(CURSOR))
			@cursor.set_position(9,60)
			@move_set.each_with_index do |move, i|
				@texts[i] = @background.add_text(15 + @cursor.width,54 + 16 * i,102,15, GameData::Skill.name(move)) if move && i < 10
			end
			descr = GameData::Text.get(7,@move_set[@index])
			pp = GameData::Skill.pp_max(@move_set[@index])
			power = GameData::Skill.power(@move_set[@index])
			accuracy = GameData::Skill.accuracy(@move_set[@index])
			cat = GameData::Skill.atk_class(@move_set[@index])
			power = "---" if power.to_s == "0"
			accuracy = "---" if accuracy.to_s == "0"
			@summary << @background.add_text(120,100,198,18,"")
			@summary[0].multiline_text = descr
			@summary << @background.add_text(120,6,198,68,"PP : #{pp}")
			@summary << @background.add_text(120,23,198,68,"#{text_get(27,37)} : #{power}")
			@summary << @background.add_text(120,40,198,68,"#{text_get(27,39)} : #{accuracy}")
			@summary << @background.add_text(120,57,198,68,"#{text_get(27,36)} :")
			@summary << @background.push(273,80,RPG::Cache.interface("c#{cat}"))
		end
		def _convert_data

			return GameData::Pokemon.move_set(@pokemon.id).each_slice(2).to_a
					
		end
		def define_move_set
			moves = Array.new
			case @mode
				when 1
					_convert_data.each do |skill|
						if skill[1] <= @pokemon.level
							moves << skill[1]
						end
					end
					GameData::Pokemon.breed_moves(@pokemon.id).each do |skill|
						moves << skill
					end
				when 2
					_convert_data.each do |skill|
						moves << skill[1]
					end
					GameData::Pokemon.breed_moves(@pokemon.id).each do |skill|
						moves << skill
					end
				else
					_convert_data.each do |skill|
						if skill[0] <= @pokemon.level
							moves << skill[1]
						end
					end
			end
			@pokemon.skills_set.each do |skill|
				if moves.include?(skill.id)
					moves.delete(skill.id)
				end
			end
			return moves
		end
		
		def update
			if(repeat?(:UP))
				if @index > 0
					@index -= 1
				else
					@index = @move_set.size - 1
				end
				refresh_summary
				refresh_skills
				update_cursor
			elsif (repeat?(:DOWN))
				if @index < @move_set.size - 1
					@index += 1
				else
					@index = 0
				end
				refresh_summary
				refresh_skills
				update_cursor
			elsif (trigger?(:A))
				$game_system.se_play($data_system.decision_se)
				scene = GamePlay::Skill_Learn.new(@pokemon, @move_set[@index])
				scene.main
				@running = false if scene.learnt == true
			elsif (trigger?(:B))
				@running = false
			end
	    end
		
		def refresh_summary
			descr = GameData::Text.get(7,@move_set[@index])
			pp = GameData::Skill.pp_max(@move_set[@index])
			power = GameData::Skill.power(@move_set[@index])
			accuracy = GameData::Skill.accuracy(@move_set[@index])
			cat = GameData::Skill.atk_class(@move_set[@index])
			power = "---" if power.to_s == "0"
			accuracy = "---" if accuracy.to_s == "0"
			@summary[0].multiline_text = descr
			@summary[1].text = "PP : #{pp}"
			@summary[2].text = "#{text_get(27,37)} : #{power}"
			@summary[3].text = "#{text_get(27,39)} : #{accuracy}"
			@summary[5].set_bitmap(RPG::Cache.interface("c#{cat}"))

		end
		def update_cursor
			if @index < 9
				@cursor.set_position(9, 60 + 16 * @index)
			else
				@cursor.set_position(9, 60 + 16 * 9)
			end
		end
		def refresh_skills
			i = 9
			if @index >= 9
				@texts.each do |text|
					text.text = GameData::Skill.name(@move_set[@index - i])
					i -= 1
				end
			elsif @index == 0
				@texts.each_with_index do |text,i|
					text.text = GameData::Skill.name(@move_set[i])
				end
			end
		end
		
		def dispose
		  super
		  #@background.dispose
		end
		  
	end
end