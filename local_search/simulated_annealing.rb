# frozen_string_literal: true

# Simulated Annealing — local search metaheuristic (Kirkpatrick et al.)
#
# Accept improving moves always; accept worsening moves with probability
# exp(−Δ/T), where the temperature T starts hot and cools geometrically.
# Early on, heat lets the search jump over ridges; as T → 0 it hardens
# into plain hill climbing that consolidates what it found. Metropolis
# acceptance, one move per temperature step.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/simulated_annealing.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module SimulatedAnnealing
  module_function

  # Yields (iteration, temperature, move, from_energy, current, verdict)
  # per step. verdict is :improved, :accepted (worsening) or :rejected.
  def search(start, initial_temperature: 50.0, cooling: 0.9, iterations: 60, rng: Random.new(42))
    current = start
    best = current
    best_energy = Problem.energy(current)
    temperature = initial_temperature

    iterations.times do |i|
      move = Problem.moves(current).reject { |m| m.trial == current }.sample(random: rng)
      delta = move.energy - Problem.energy(current)

      if delta.negative? || delta.zero?
        verdict = move.energy < best_energy ? :improved : :side_step
        probability = nil
      else
        probability = Math.exp(-delta / temperature)
        verdict = rng.rand < probability ? :accepted : :rejected
      end

      details = { delta: delta, probability: probability, best_energy: best_energy }
      yield i + 1, temperature, move, current, verdict, details if block_given?

      current = move.trial if verdict != :rejected
      if Problem.energy(current) < best_energy
        best = current
        best_energy = Problem.energy(current)
      end
      temperature = [temperature * cooling, 0.01].max
    end

    best
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Simulated Annealing", "local search · Metropolis acceptance")
  puts "   #{dim('Worsening moves are accepted with probability exp(−Δ/T);')}"
  puts "   #{dim('the temperature cools geometrically until the search freezes.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))
  puts

  final = SimulatedAnnealing.search(seed) do |it, temperature, move, _state, verdict, details|
    thermo = format("T %5.1f", temperature)
    delta = details[:delta]
    label =
      case verdict
      when :improved then sage("accept — improves, new best")
      when :side_step then gray("accept — side step")
      when :accepted then gold(format("accept — worse, p=%.2f", details[:probability]))
      else coral(format("reject — worse, p=%.2f", details[:probability]))
      end
    delta_text = delta.positive? ? coral("+#{delta}") : sage(delta.to_s)
    puts "   #{gray(format('it %-2d', it))} #{bold(format('%-16s', move.description))} #{gray(thermo)}  Δ #{delta_text}   #{label}"
  end

  puts
  puts "   #{bold('Best state found')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  note("early heat took the jumps; the final freeze kept the gains")
  ok("annealing crossed the ridge while it was still hot") if Problem.energy(final) <= 1
end
