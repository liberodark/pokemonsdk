module Battle
  module Effects
    class Item
      class Gems < Item
        # List of conditions to yield the base power multiplier
        CONDITIONS = {}
        # List of multiplier if conditions are met
        MULTIPLIERS = Hash.new(1.3)
        # Function called before the accuracy check of a move is done
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param targets [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_pre_accuracy_check(logic, scene, targets, launcher, skill)
          return unless targets.any? { |target| usable_gem?(launcher, target, skill) }

          logic.scene.visual.show_item(launcher)
          launcher.item_consumed = true
        end

        # Give the move mod3 mutiplier (after everything)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def mod3_multiplier(user, target, move)
          return super unless usable_gem?(user, target, move)

          @logic.item_change_handler.change_item(:none, true, user)
          return MULTIPLIERS[db_symbol]
        end

        private

        # Check whether the launcher can use its gem
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        def usable_gem?(user, target, move)
          return false if user != @target
          return false if move.ohko? || move.typeless? || move.be_method == :s_pledge
          return false unless CONDITIONS[db_symbol].call(user, target, move)

          return true
        end

        class << self
          # Register an item with base power multiplier only
          # @param db_symbol [Symbol] db_symbol of the item
          # @param multiplier [Float] multiplier if condition met
          # @param klass [Class<BasePowerMultiplier>] klass to instanciate
          # @param block [Proc] condition to verify
          # @yieldparam user [PFM::PokemonBattler] user of the move
          # @yieldparam target [PFM::PokemonBattler] target of the move
          # @yieldparam move [Battle::Move] move
          # @yieldreturn [Boolean]
          def register(db_symbol, multiplier = nil, klass = Gems, &block)
            Item.register(db_symbol, klass)
            CONDITIONS[db_symbol] = block
            MULTIPLIERS[db_symbol] = multiplier if multiplier
          end
        end

        register(:fire_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:fire).id) }
        register(:water_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:water).id) }
        register(:electric_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:electric).id) }
        register(:grass_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:grass).id) }
        register(:ice_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:ice).id) }
        register(:fighting_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:fighting).id) }
        register(:poison_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:poison).id) }
        register(:ground_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:ground).id) }
        register(:flying_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:flying).id) }
        register(:psychic_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:psychic).id) }
        register(:bug_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:bug).id) }
        register(:rock_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:rock).id) }
        register(:ghost_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:ghost).id) }
        register(:dragon_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:dragon).id) }
        register(:dark_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:dark).id) }
        register(:steel_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:steel).id) }
        register(:fairy_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:fairy).id) }
        register(:normal_gem) { |user, target, move| move.definitive_types(user, target).include?(data_type(:normal).id) }        
      end
    end
  end
end