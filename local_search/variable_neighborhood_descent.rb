# frozen_string_literal: true

# Variable Neighborhood Descent — local search metaheuristic (Mladenović & Hansen)
#
# One neighborhood's local optimum is not the truth — it is just where
# one move family ran out. VND descends with neighborhood N1; when N1
# cannot improve anymore, it switches to N2, and a move there can reopen
# N1. The search only ends when NO neighborhood offers improvement.
#
# N1: reassign one task (change moves) — gets trapped on this instance.
# N2: exchange two tasks' machines (swap moves) — the way out.
#
# Run me: ruby local_search/variable_neighborhood_descent.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module VariableNeighborhoodDescent
  NEIGHBORHOODS = [
    { name: "N1 change", pool: ->(state) { Problem.change_moves(state) } },
    { name: "N2 swap",   pool: ->(state) { Problem.swap_moves(state) } }
  ].freeze

  module_function

  # Yields (iteration, neighborhood_name, move, from_energy, current, event)
  # per accepted move; event is :descend or :switch.
  def search(start)
    current = start
    iteration = 0

    loop do
      neighborhood, index = NEIGHBORHOODS.each_with_index.find do |n, _|
        move = n[:pool].call(current).min_by(&:energy)
        move && move.energy < Problem.energy(current)
      end

      break if neighborhood.nil?   # every neighborhood is at a local optimum

      move = neighborhood[:pool].call(current).min_by(&:energy)
      from_energy = Problem.energy(current)
      current = move.trial
      iteration += 1
      event = neighborhood[:name].start_with?("N2") ? :switch : :descend
      yield iteration, neighborhood[:name], move, from_energy, current, event
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Variable Neighborhood Descent", "local search · Mladenović & Hansen")
  puts "   #{dim('Descend in N1 until stuck, then try N2; an N2 move reopens N1.')}"
  puts "   #{dim('Stop only when every neighborhood is at a local optimum.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))
  puts

  final = VariableNeighborhoodDescent.search(seed) do |it, name, move, from_energy, state, event|
    label = event == :switch ? gold("neighborhood switch — N1 was exhausted") : gray("descend in #{name}")
    puts "   #{gray(format('it %-2d', it))} #{violet(format('%-9s', name))} #{bold(format('%-16s', move.description))} " \
         "#{energy_value(from_energy)} #{sage('→')} #{energy_value(Problem.energy(state))}   #{label}"
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  ok("N2's swap rescued the descent that N1's changes could not finish")
end
