module Battle
  class Logic
    # Class describing the informations about the battle
    class BattleInfo
      # @return [Array<Array<String>>] List of the name of the battlers according to the bank & their position
      attr_accessor :names
      # @return [Array<Array<String>>] List of the classes of the battlers according to the bank & their position
      attr_accessor :classes
      # @return [Array<Array<String>>] List of the battler (image) name of the battlers according to the bank
      attr_accessor :battlers
      # @return [Array<Array<PFM::Bag>>] List of the bags of the battlers according to the bank
      attr_accessor :bags
      # @return [Array<Array<Array<PFM::Pokemon>>>] List of the "Party" of the battlers according to the bank & their position
      attr_accessor :parties
      # @return [Array<Array<Integer>>] List of the base money of the battlers according to the bank
      attr_accessor :base_moneys
      # @return [Integer, nil] Maximum level allowed for the battle
      attr_accessor :max_level
      # @return [Integer] Number of Pokemon fighting at the same time
      attr_accessor :vs_type
      # @return [Integer] Reason of the wild battle
      attr_accessor :wild_battle_reason
      # @return [Boolean] if the trainer battle is a "couple" battle
      attr_accessor :trainer_is_couple
      # @return [Integer] ID of the battle (for event loading)
      attr_accessor :battle_id
      # Get the number of time the player tried to flee
      # @return [Integer]
      attr_accessor :flee_attempt_count
      # Tell if the battle follows a fishing attempt
      # @return [Boolean]
      attr_accessor :fishing
      # Get the caught Pokemon
      # @return [PFM::PokemonBattler]
      attr_accessor :caught_pokemon

      # Create a new Battle Info
      # @param hash [Hash] basic info about the battle
      def initialize(hash = {})
        @names = hash[:names] || [[], []]
        @classes = hash[:classes] || [[], []]
        @battlers = hash[:battlers] || [[], []]
        @bags = hash[:bags] || [[], []]
        @parties = hash[:parties] || [[], []]
        @base_moneys = hash[:base_moneys] || [[], []]
        @max_level = hash[:max_level] || nil
        @vs_type = hash[:vs_type] || 1
        @trainer_is_couple = hash[:couple] || false
        @battle_id = hash[:battle_id] || -1
        @flee_attempt_count = 0
        @fishing = hash[:fishing] || false #TODO Add the fishing attribute to the BattleInfo initialization
      end

      class << self
        # Configure a PSDK battle from old settings
        # @param id_trainer1 [Integer]
        # @param id_trainer2 [Integer]
        # @param id_friend [Integer]
        # @return battle_info [Battle::Logic::BattleInfo]
        def from_old_psdk_settings(id_trainer1, id_trainer2 = 0, id_friend = 0)
          battle_info = BattleInfo.new
          # Add Player party
          battle_info.add_party(0, *player_basic_info)
          # Add 1st enemy
          add_trainer(battle_info, 1, id_trainer1)
          # Add 2nd enemy
          add_trainer(battle_info, 1, id_trainer2) if id_trainer2 != 0
          # Add friend
          add_trainer(battle_info, 0, id_friend) if id_friend != 0
          battle_info.vs_type = 2 if battle_info.trainer_is_couple || battle_info.parties[1]&.size == 2
          return battle_info
        end

        # Configure a PSDK battle for wild battle
        # @param wild_group [Array<PFM::Pokemon>]
        # @return battle_info [Battle::Logic::BattleInfo]
        def wild_battle_info(wild_group)
          battle_info = Battle::Logic::BattleInfo.new
          battle_info.add_party(0, *player_basic_info)
          battle_info.add_party(1, wild_group)
          battle_info.vs_type = 2 if wild_group.size >= 2
          return battle_info
        end

        # Add a trainer to the battle_info object
        # @param battle_info [BattleInfo]
        # @param bank [Integer] bank of the trainer
        # @param id_trainer [Integer] ID of the trainer in the database
        def add_trainer(battle_info, bank, id_trainer)
          trainer = GameData::Trainer[id_trainer]
          klass = GameData::Trainer.class_name(id_trainer)
          battler = trainer.battler
          name = trainer.internal_names[battle_info.parties[1]&.size || 0]
          party = trainer.team.map { |hash| PFM::Pokemon.generate_from_hash(hash) }
          battle_info.add_party(bank, party, name, klass, battler)
          battle_info.base_moneys[bank] << trainer.base_money if bank == 1
          battle_info.trainer_is_couple = battle_info.parties[1].size == 1 if bank == 1 && trainer.vs_type == 2
        end
      end

      # Tell if the battle is a trainer battle
      # @return [Boolean]
      def trainer_battle?
        !@names[1].empty?
      end

      # Return the basic info about the player
      # @return [Array]
      def player_basic_info
        return $actors, $trainer.name, GameData::Trainer.class_name(0), $game_actors[1].battler_name, $bag
      end

      # Add a party to a bank
      # @param bank [Integer] bank where the party should be defined
      # @param party [Array<PFM::Pokemon>] Pokemon of the battler
      # @param name [String, nil] name of the battler (don't set it if Wild Battle)
      # @param klass [String, nil] name of the battler (don't set it if Wild Battle)
      # @param battler [String, nil] name of the battler image (don't set it if Wild Battle)
      # @param bag [String, nil] bag used by the party
      def add_party(bank, party, name = nil, klass = nil, battler = nil, bag = nil, base_money = nil)
        @parties[bank] ||= []
        @parties[bank] << party
        @names[bank] ||= []
        @names[bank] << name if name
        @classes[bank] ||= []
        @classes[bank] << klass if klass
        @battlers[bank] ||= []
        @battlers[bank] << battler if battler
        @bags[bank] ||= []
        @bags[bank] << (bag || PFM::Bag.new)
        @base_moneys[bank] ||= []
        @base_moneys[bank] << base_money if base_money
      end

      # Get the trainer name of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [String]
      def trainer_name(battler)
        return @names[battler.bank][party_index(battler)]
      end

      # Get the trainer class of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [String]
      def trainer_class(battler)
        return @classes[battler.bank][party_index(battler)]
      end

      # Get the bag of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [PFM::Bag]
      def bag(battler)
        return @bags[battler.bank][party_index(battler)]
      end

      # Get the party of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Array<PFM::Pokemon>]
      def party(battler)
        return @parties[battler.bank][party_index(battler)]
      end

      # Get the base money of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Integer]
      def base_money(battler)
        return @base_money[battler.bank][party_index(battler)]
      end

      private

      # Find the party index of a battler
      # @param battler [PFM::PokemonBattler]
      # @return [Integer]
      def party_index(battler)
        return @parties[battler.bank].index(battler.original) || 0
      end
    end
  end
end
