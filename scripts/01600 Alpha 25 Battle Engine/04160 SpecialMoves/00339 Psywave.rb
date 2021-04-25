#Generation 5 and onwards formula: (user's level) * (r + 50) / 100, where r is a random number from 0 to 100 always rounded down. Never should be 0.
module Battle
    class Move
      class Psywave < Basic
        private
        def real_base_power(user, target)
		n = (user.level * (logic.move_damage_rng.rand(1..100) + 50) / 100).floor
		if n < 1
		  log_data("RNG gave you 0, so we'll set power to 1.")
		  return 1
		else
		  log_data("RNG was nice. Actual Power: #{n}")
          return n
		end
        return power
      end
    end
    Move.register(:s_psywave, Psywave)
  end
end