module Battle
  module Effects
    class Ability
      class TabletsOfRuin < Ability
        # Create a new Tablets of Ruin effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          remove_effect(handler, who) if who != with && who == @target && @activated
          set_effect(handler, with) if with == @target
        end

        # Function responsible for applying the effect
        # @param handler [Battle::Logic::SwitchHandler]
        # @param owner [PFM::PokemonBattler]
        def set_effect(handler, owner)
          battlers = handler.logic.all_alive_battlers.reject { |battler| battler == owner }
          return if battlers.empty?

          battlers.each do |battler|
            next if battler.has_ability?(db_symbol) || battler.effects.has?(db_symbol)

            battler.effects.add(effect_class.new(handler.logic))
          end

          handler.scene.visual.show_ability(owner)
          handler.scene.visual.wait_for_animation
          #TODO: Add the corresponding text
          @activated = true
        end

        # Function responsible for removing the effect
        # @param handler [Battle::Logic::SwitchHandler]
        # @param owner [PFM::PokemonBattler]
        def remove_effect(handler, owner)
          battlers = handler.logic.all_alive_battlers.reject { |battler| battler == owner }
          return if battlers.empty?

          battlers.each do |battler|
            next unless battler.has_ability?(db_symbol) || battler.effects.has?(db_symbol)

            battler.effects.get(db_symbol)&.kill
            battler.effects.delete_specific_dead_effect(db_symbol)
          end
          @activated = false
        end

        # If Tablets of Ruin is currently activated by this pokemon
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?

        # Class of the Effect given by this ability
        def effect_class
          return Effects::TabletsOfRuin
        end
      end

      class BeadsOfRuin < TabletsOfRuin
        # Class of the Effect given by this ability
        def effect_class
          return Effects::BeadsOfRuin
        end
      end

      class VesselOfRuin < TabletsOfRuin
        # Class of the Effect given by this ability
        def effect_class
          return Effects::VesselOfRuin
        end
      end

      class SwordOfRuin < VesselOfRuin
        # Class of the Effect given by this ability
        def effect_class
          return Effects::SwordOfRuin
        end
      end

      register(:tablets_of_ruin, TabletsOfRuin)
      register(:beads_of_ruin, BeadsOfRuin)
      register(:vessel_of_ruin, VesselOfRuin)
      register(:sword_of_ruin, SwordOfRuin)
    end
  end
end
