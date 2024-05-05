module Battle
  module Effects
    class Item
      class Berry < Item
        # List of berry flavors
        FLAVORS = %i[spicy dry sweet bitter sour]

        # Function that executes the effect of the berry (for Pluck & Bug Bite)
        # @param force_heal [Boolean] tell if a healing berry should force the heal
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def execute_berry_effect(force_heal: false, force_execution: false)
          return nil
        end

        private

        # Function that consumes the berry
        # @param holder [PFM::PokemonBattler] pokemon holding the berry
        # @param launcher [PFM::PokemonBattler] potential user of the move
        # @param move [Battle::Move] potential move
        # @param should_confuse [Boolean] if the berry should confuse the Pokemon if he does not like the taste
        def consume_berry(holder, launcher = nil, move = nil, should_confuse: false)
          # TODO: show eating of berry
          @logic.item_change_handler.change_item(:none, true, holder, launcher, move) if holder.hold_item?(db_symbol)
          if should_confuse && (data = Yuki::Berries::BERRY_DATA[db_symbol])
            taste = FLAVORS.max_by { |flavor| data.send(flavor) } || FLAVORS.first
            return unless holder.flavor_disliked?(taste)
            return unless @logic.status_change_handler.status_appliable?(:confuse, holder, launcher, move)

            @logic.status_change_handler.status_change(:confusion, holder, launcher, move)
          end
          if holder.has_ability?(:cheek_pouch) && !holder.effects.has?(:heal_block)
            @logic.scene.visual.show_ability(holder)
            @logic.damage_handler.heal(holder, holder.max_hp / 3)
          end
        end

        # Function that tests if berry cannot be consumed
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        # @return [Boolean]
        def cannot_be_consumed?(force_execution = false)
          return false if force_execution

          return @logic.foes_of(@target).any? { |foe| %i[unnerve as_one].include?(foe.battle_ability_db_symbol) && foe.alive? }
        end
      end
    end
  end
end
