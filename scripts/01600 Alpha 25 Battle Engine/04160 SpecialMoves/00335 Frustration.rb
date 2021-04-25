module Battle
    class Move
      class Frustration < Basic
        private
        def real_base_power(user, targets)
          return ((255 - user.loyalty) / 2.5)
		  if user.loyalty > 0
		    return power
		  else 
		    return 1
		  end
		  log_data("Power: #{power}")
		end
      end
      Move.register(:s_frustration, Frustration)
    end
  end
  