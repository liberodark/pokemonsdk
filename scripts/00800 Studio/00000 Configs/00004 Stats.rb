module Configs
  # Configuration of stats
  class Stats
    # Maximum amount of EV
    # @return [Integer]
    attr_accessor :max_total_ev

    # Maximum amount of EV on a stat
    # @return [Integer]
    attr_accessor :max_stat_ev

    # Index of each hp ev
    # @return [Integer]
    attr_accessor :hp_index

    # Index of atk ev
    # @return [Integer]
    attr_accessor :atk_index

    # Index of dfe ev
    # @return [Integer]
    attr_accessor :dfe_index

    # Index of spd ev
    # @return [Integer]
    attr_accessor :spd_index

    # Index of ats ev
    # @return [Integer]
    attr_accessor :ats_index

    # Index of dfs ev
    # @return [Integer]
    attr_accessor :dfs_index

    # Index of atk stage
    # @return [Integer]
    attr_accessor :atk_stage_index

    # Index of dfe stage
    # @return [Integer]
    attr_accessor :dfe_stage_index

    # Index of spd stage
    # @return [Integer]
    attr_accessor :spd_stage_index

    # Index of ats stage
    # @return [Integer]
    attr_accessor :ats_stage_index

    # Index of dfs stage
    # @return [Integer]
    attr_accessor :dfs_stage_index

    # Index of eva stage
    # @return [Integer]
    attr_accessor :eva_stage_index

    # Index of acc stage
    # @return [Integer]
    attr_accessor :acc_stage_index

    def initialize
      @max_total_ev = 510
      @max_stat_ev = 252
      @hp_index = 0
      @atk_index = 1
      @dfe_index = 2
      @spd_index = 3
      @ats_index = 4
      @dfs_index = 5
      @atk_stage_index = 0
      @dfe_stage_index = 1
      @spd_stage_index = 2
      @ats_stage_index = 3
      @dfs_stage_index = 4
      @eva_stage_index = 5
      @acc_stage_index = 6
    end

    # Convert the config to json
    def to_json(*)
      {
        klass: self.class.to_s,
        max_total_ev: @max_total_ev,
        max_stat_ev: @max_stat_ev,
        hp_index: @hp_index,
        atk_index: @atk_index,
        dfe_index: @dfe_index,
        spd_index: @spd_index,
        ats_index: @ats_index,
        dfs_index: @dfs_index,
        atk_stage_index: @atk_stage_index,
        dfe_stage_index: @dfe_stage_index,
        spd_stage_index: @spd_stage_index,
        ats_stage_index: @ats_stage_index,
        dfs_stage_index: @dfs_stage_index,
        eva_stage_index: @eva_stage_index,
        acc_stage_index: @acc_stage_index
      }.to_json
    end
  end
  # @!method self.stats
  #   @return [Stats]
  register(:stats, 'stats', :json, false, Stats)
end
