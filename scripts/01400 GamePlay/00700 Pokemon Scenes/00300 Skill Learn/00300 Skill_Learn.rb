module GamePlay
  class Skill_Learn < BaseCleanUpdate
    Skill_Learn = "skill_learn"
    include UI
    include UI::Skill_Learn
    attr_accessor :learnt
    # Create a new Skill Learn scene
    # param pokemon [PFM::Pokemon]
    # param skill [Integer] or [Symbol]
    def initialize(pokemon, skill_id)
      super()
      @pokemon = pokemon
      @skill_id = skill_id
      @skill_learn = PFM::Skill.new(@skill_id)
      @skill_set_not_full = @pokemon.skills_set.size < 4
      @skills = @pokemon.skills_set
      @index = 4
      @learnt = false
      @state = :start
      @running = true
    end
  end
end