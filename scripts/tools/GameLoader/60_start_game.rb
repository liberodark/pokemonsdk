begin
  $GAME_LOOP.call
rescue Exception
  display_game_exception('An error occured during Game Loop.')
end
