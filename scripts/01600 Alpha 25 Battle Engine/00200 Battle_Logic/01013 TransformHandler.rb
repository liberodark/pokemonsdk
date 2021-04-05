module Battle
  class Logic
    # Handler responsive of answering properly transform requests
    class TransformHandler < ChangeHandlerBase
      include Hooks
      # Function responsive of transforming a Pokemon when initialized
      # @param target [PFM::PokemonBattler]
      def initialize_transform_attempt(target)
        exec_hooks(TransformHandler, :on_initialize_transform, binding)
      end

      class << self
        # Function that registers a on_initialize_transform hook
        # @param reason [String] reason of the on_initialize_transform registration
        # @yieldparam handler [TransformHandler]
        # @yieldparam target [PFM::PokemonBattler] pokemon to try to transform on initialize
        # @yieldreturn [nil]
        def register_on_initialize_transform(reason)
          Hooks.register(TransformHandler, :on_initialize_transform, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:target)
            )
          end
        end
      end
    end

    TransformHandler.register_on_initialize_transform('PSDK: Illusion') do |handler, target|
      next if target.original.ability_db_symbol != :illusion

      party = handler.logic.battle_info.party(target)
      next if party.empty? || party.index(target) == (party.size - 1)

      target.transform = party.last
    end
  end
end
