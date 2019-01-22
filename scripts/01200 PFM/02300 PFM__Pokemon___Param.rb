#encoding: utf-8

module PFM
  class Pokemon
    # PSP 0.7 ID Hash key
    G_ID = "ID"
    # PSP 0.7 level Hash key
    G_NV = "NV"
    # PSP 0.7 item hash key
    G_OBJ = "OBJ"
    # PSP 0.7 stat hash key
    G_STAT = "STAT"
    # PSP 0.7 move hash key
    G_MOVE = "MOVE"
    # PSP 0.7 gender hash key
    G_GR = "GR"
    # PSP 0.7 form hash key
    G_FORM = "FORM"
    # PSP 0.7 shiny hash key
    G_SHINY = "SHINY"
    # Generate a Pokemon from a hash
    # 
    #   Hash structure :
    #     id: Integer # ID of the Pokemon in the database
    #     level: Integer # Level of the Pokemon
    #     item: opt Integer # ID of the item the Pokemon holds
    #     stats: opt Array<Integer> # IV of the Pokemon [hp, atk, dfe, spd, ats, dfs]
    #     moves: opt Array<Integer> # List of skill/move ID in the database
    #     gender: opt Integer/String # "i", 0, "m", 1, "f", 2
    #     shiny: Boolean # If the Pokemon is shiny
    #     no_shiny: Boolean # If the Pokemon cannot be shiny
    #     form: opt Integer # The form of the Pokemon
    #     rareness: opt Integer # The pokemon rareness (0 = uncatchable)
    #     trainer_name: opt String # Trainer name of the Pokemon
    #     trainer_id: opt Integer # Trainer id of the Pokemon
    #     given_name: opt String # Given name of the Pokemon
    #     loyalty: opt Integer # Loyalty of the Pokemon
    #     ball: opt Integer # ID of the ball used to catch the Pokemon
    #     bonus: opt Array<Integer> # EV of the Pokemon [hp, atk, dfe, spd, ats, dfs]
    #     nature: opt Integer # Nature of the Pokemon
    # @param hash [Hash] the hash parameter of the Pokemon
    # @return [PFM::Pokemon]
    def self.generate_from_hash(hash)
      pkmn_id=hash[:id]
      unless pkmn_id #On est donc en mode PSP 0.7
        pkmn_id=hash[G_ID]
        lvl=hash[G_NV]
        sexe=hash[G_GR]
        moves=hash[G_MOVE]
        form=hash[G_FORM]
        shiny=hash[G_SHINY]
        stat=hash[G_STAT]
        obj=hash[G_OBJ]
      else
        lvl=hash[:level]
        obj=hash[:item]
        stat=hash[:stats]
        moves=hash[:moves]
        sexe=hash[:gender]
        form=hash[:form]
        shiny=hash[:shiny]
        no_shiny = hash[:no_shiny]
        rareness=hash[:rareness]
        bonus=hash[:bonus]
        trainer_name = hash[:trainer_name]
        given_name = hash[:given_name]
        trainer_id = hash[:trainer_id]
        loyalty = hash[:loyalty]
        ability = hash[:ability]
        ball = hash[:ball]
      end
      pokemon=PFM::Pokemon.new(pkmn_id,lvl.to_i,shiny,no_shiny, form ? form : -1)
      pokemon.trainer_id = trainer_id if trainer_id
      pokemon.trainer_name = trainer_name if trainer_name
      pokemon.given_name = given_name if given_name
      pokemon.code_generation(shiny)
      pokemon.dv_modifier(stat) if stat and stat.size==6
      pokemon.set_gender(sexe) if sexe
      if obj
        success = !hash[:item_rate]
        success = rand(100) < hash[:item_rate] unless success
        pokemon.item_holding = obj if success
      end
      #pokemon.form=form if form
      pokemon.rareness=rareness if rareness
      pokemon.add_bonus(bonus) if bonus
      pokemon.loyalty = loyalty if loyalty
      pokemon.ability_current = pokemon.ability = ability if ability
      pokemon.captured_with = ball if ball
      if moves
        moves.each_with_index do |skill, j|
          next if skill == 0 #> On ignore les Aucun
          if(skill.is_a?(Integer))
            pokemon.replace_skill_index(j, skill)#.skills_set[j] = PFM::Skill.new(skill)
          else
            #pokemon.skills_set[j] = nil
            print("Erreur, ",skill," est irrecevable, vous devez spécifier un id !","PSDK_ERR n°000_001") if skill.class == String
          end
        end
        pokemon.skills_set.compact!
      end
      pokemon.nature = hash.fetch(:nature, pokemon.nature_id)
      return pokemon
    end
  end
end
