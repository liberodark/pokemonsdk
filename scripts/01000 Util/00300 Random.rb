#encoding: utf-8

# Class in charge of generating random numbers
#
# Here PSDK will store constants to make separate random generators
class Random
  # WildBattle random generator
  WildBattle = Random.new
  # IV hp random generator
  IV_HP = Random.new
  # IV atk random generator
  IV_ATK = Random.new
  # IV dfe random generator
  IV_DFE = Random.new
  # IV spd random generator
  IV_SPD = Random.new
  # IV ats random generator
  IV_ATS = Random.new
  # IV dfs random generator
  IV_DFS = Random.new
  # Mining Game's items random generator
  MiningGameItem = Random.new
  # Mining Game's tiles random generator
  MiningGameTiles = Random.new
  # Mining Game's obstacles random generator
  MiningGameObstacles = Random.new
end
