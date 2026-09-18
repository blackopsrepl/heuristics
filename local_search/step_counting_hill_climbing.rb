# frozen_string_literal: true

# Step Counting Hill Climbing — local search metaheuristic (Schönberger)
#
# Hill climbing, but with a small budget of "side steps": a candidate is
# accepted when it is not worse than the current state, OR while the
# step counter is below the limit — and every non-improving step costs
# counter budget, refilled only when a new global best appears. The
# counter turns blind acceptance into a measured walk across ridges.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/step_counting_hill_climbing.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module StepCountingHillClimbing
  module_function

  # Yields (iteration, move, from_energy, current, verdict) per accepted step.
  # Returns the best state seen along the walk — not the last one.
  def search(start, step_limit: 2, iterations: 24, rng: Random.new(42))
    current = start
    best = current
    best_energy = Problem.energy(current)
    steps = 0

    iterations.times do |i|
      move = Problem.moves(current).shuffle(random: rng).first
      from_energy = Problem.energy(current)
      to_energy = move.energy

      accepted = to_energy <= from_energy || steps < step_limit
      next unless accepted

      verdict =
        if to_energy < best_energy
          best = move.trial
          best_energy = to_energy
          steps = 0
          "new best — counter reset"
        elsif to_energy <= from_energy
          "side step"
        else
          steps += 1
          "tolerated worse (#{steps}/#{step_limit})"
        end
      current = move.trial
      yield i + 1, move, from_energy, current, verdict
    end

    best
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Step Counting Hill Climbing", "local search · Schönberger rule")
  puts "   #{dim('Accept non-worsening moves — or anything at all while the step')}"
  puts "   #{dim('counter has budget. Worsening steps spend it; new bests refill it.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))

  final = StepCountingHillClimbing.search(seed) do |it, move, from_energy, state, verdict|
    iteration(it, move.description, from_energy, Problem.energy(state), verdict)
  end

  puts
  puts "   #{bold('Best state seen along the walk')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  note("the walk itself keeps wandering — SCHC reports the best state visited")
  ok("the side-step budget crossed the ridge plain climbing cannot") if Problem.energy(final) <= 1
end
