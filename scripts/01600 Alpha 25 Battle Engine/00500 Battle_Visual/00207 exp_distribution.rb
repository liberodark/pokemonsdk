module Battle
  class Visual
    # Show the exp distribution
    # @param exp_data [Hash{ PFM::PokemonBattler => Integer }] info about experience each pokemon should receive
    def show_exp_distribution(exp_data)
      lock do
        exp_ui = BattleUI::ExpDistribution.new(@viewport_sub, @scene, exp_data)
        exp_ui.start_animation
        scene_update_proc { exp_ui.update } until exp_ui.done?
      end
      exp_data.each_key { |pokemon| refresh_info_bar(pokemon) if @scene.battle_info.vs_type > pokemon.position }
    end
  end
end
