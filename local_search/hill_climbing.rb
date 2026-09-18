# frozen_string_literal: true

# Hill Climbing — local search metaheuristic
#
# The simplest local search there is: look at the neighbors, move to the
# best one, repeat. No memory, no randomness, no escape hatches. When
# every neighbor is worse or equal, you stop — even if a far better
# solution sits across the valley. This demo runs the classic descent
# on the shared assignment problem and, truthfully, gets stuck: plain
# descent is exactly why the other metaheuristics exist.
#
# Neighborhood: reassign one task (change moves only).
#
# Run me: ruby local_search/hill_climbing.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module HillClimbing
  module_function

  # Steepest descent; yields (iteration, move, from_energy, current)
  # per accepted step.
  def search(start)
    current = start
    iteration = 0

    loop do
      best = Problem.change_moves(current).min_by(&:energy)
      break if best.nil? || best.energy >= Problem.energy(current)
      from_energy = Problem.energy(current)
      current = best.trial
      iteration += 1
      yield iteration, best, from_energy, current if block_given?
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Hill Climbing", "local search · steepest descent")
  puts "   #{dim('Move to the best neighbor while one exists; stop at the first')}"
  puts "   #{dim('local optimum. Neighborhood: reassign one task (change moves).')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))
  note("m1 8/8 full · m2 4/7 · m3 7/6 — one task over")

  final = HillClimbing.search(seed) do |it, move, from_energy, state|
    iteration(it, move.description, from_energy, Problem.energy(state), "accepted (better)")
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  miss("stuck: every single reassignment is worse or equal — a local optimum")
  note("escaping needs a bigger move than one reassignment. See how:")
  note("  tabu_search.rb · simulated_annealing.rb · variable_neighborhood_descent.rb")
end
