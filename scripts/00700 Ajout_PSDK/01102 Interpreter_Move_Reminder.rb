class Interpreter
	def move_reminder (pokemon = $pokemon_party.actors[$game_variables[::Yuki::Var::Party_Menu_Sel]], mode = 0)
		$scene = GamePlay::Move_Reminder.new(pokemon,mode)
	    Graphics.transition
		@wait_count = 2
	end
	alias maitre_capacites move_reminder
end