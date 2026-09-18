# frozen_string_literal: true

# Diversified Late Acceptance — local search metaheuristic
#
# Late Acceptance with a third acceptance channel: a candidate that
# beats the best-so-far by a tolerance margin is accepted even when it
# loses to both the current state and the history buffer. The margin
# deliberately lets the search wander near the top of the landscape, so
# basins around the optimum get visited instead of one path being
# committed to too early.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/diversified_late_acceptance.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module DiversifiedLateAcceptance
  module_function

  # Yields (iteration, move, from_energy, current, channel, threshold)
  # per step. Channels: :current, :history, :diversify, :rejected.
  def search(start, history_size: 3, tolerance: 0.5, iterations: 25, rng: Random.new(42))
    current = start
    best_energy = Problem.energy(current)
    history = Array.new(history_size, Problem.energy(current))
    pointer = 0

    iterations.times do |i|
      from_energy = Problem.energy(current)
      threshold = best_energy * (1.0 + tolerance)

      # evaluate shuffled candidates until one is accepted
      channel = :rejected
      move = nil
      Problem.moves(current).shuffle(random: rng).each do |candidate_move|
        move = candidate_move
        candidate = move.energy
        channel =
          if candidate <= from_energy then :current
          elsif candidate <= history[pointer] then :history
          elsif candidate <= threshold then :diversify
          else :rejected
          end
        break unless channel == :rejected
      end

      if channel != :rejected
        best_energy = [best_energy, move.energy].min
        history[pointer] = from_energy
        pointer = (pointer + 1) % history_size
        current = move.trial
      end

      yield i + 1, move, from_energy, current, channel, threshold
      break if Problem.energy(current) <= 1
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Diversified Late Acceptance", "local search · Burke & Bykov + tolerance")
  puts "   #{dim('Late Acceptance plus a diversification channel: anything within')}"
  puts "   #{dim('a tolerance band of the best-so-far is fair game. Wander near the top.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))
  puts

  final = DiversifiedLateAcceptance.search(seed) do |it, move, from_energy, state, channel, threshold|
    label = case channel
            when :current then sage("beats current")
            when :history then gold("beats history")
            when :diversify then violet(format("within tolerance (≤ %.0f)", threshold))
            else coral("rejected")
            end
    puts "   #{gray(format('it %-2d', it))} #{bold(format('%-16s', move.description))} " \
         "#{energy_value(from_energy)} #{channel == :rejected ? coral('→') : sage('→')} #{energy_value(Problem.energy(state))}   #{label}"
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  ok("the tolerance band kept alternatives reachable near the optimum") if Problem.energy(final) <= 1
end
