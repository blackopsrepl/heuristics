# frozen_string_literal: true

# Tabu Search — local search metaheuristic (Glover)
#
# Always take the best admissible neighbor — even a worsening one — and
# make going back taboo for a while. A short-term memory of forbidden
# reversals forces the search off the beaten track; an aspiration rule
# still allows a taboo move when it beats the best solution ever seen.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/tabu_search.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module TabuSearch
  Tabu = Struct.new(:task, :machine, :expires)

  module_function

  # a move is taboo when it sends some task back to a machine
  # it was forbidden to return to
  def tabued?(current, trial, tabu)
    current.each_index.any? do |task|
      next false if current[task] == trial[task]
      tabu.any? { |entry| entry.task == task && entry.machine == trial[task] }
    end
  end

  # Yields (iteration, move, from_energy, current, best_energy, tabu) per step.
  def search(start, tenure: 3, iterations: 15)
    current = start
    best_energy = Problem.energy(current)
    tabu = []

    iterations.times do |i|
      # the aspiration rule: taboo moves are admissible if they beat the best
      pool = Problem.moves(current).select do |move|
        !tabued?(current, move.trial, tabu) || move.energy < best_energy
      end
      move = pool.min_by(&:energy)
      break if move.nil?

      from_energy = Problem.energy(current)
      current.each_index do |task|
        next if current[task] == move.trial[task]
        tabu << Tabu.new(task, current[task], i + tenure)
      end
      tabu.reject! { |entry| entry.expires <= i + 1 }

      current = move.trial
      best_energy = [best_energy, move.energy].min
      yield i + 1, move, from_energy, current, best_energy, tabu.dup
      break if move.energy <= 1
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Tabu Search", "local search · Glover")
  puts "   #{dim('Take the best admissible neighbor, even uphill, and forbid')}"
  puts "   #{dim('undoing it for a tenure of iterations. Memory beats myopia.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))

  final = TabuSearch.search(seed) do |it, move, from_energy, state, _best, tabu|
    list = tabu.empty? ? gray("∅") : tabu.map { |t| gray("t#{t.task + 1}∉m#{t.machine + 1}") }.join(" ")
    iteration(it, move.description, from_energy, Problem.energy(state), "tabu: #{list}")
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  ok("the taboo on reversals pushed the search past the local optimum")
end
