# frozen_string_literal: true

# Great Deluge — local search metaheuristic (Dueck)
#
# Picture the search landscape flooding. A candidate is accepted when
# it stays above the water level — never mind whether it beats the
# current state. Every iteration it rains (for minimization: the level
# drops), so the constraint tightens steadily and the search is squeezed
# toward the peaks. One knob, the rain speed, sets the whole schedule.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/great_deluge.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module GreatDeluge
  module_function

  # Yields (iteration, move, from_energy, current, water, channel)
  # per step. Channels: :current, :water, :rejected.
  def search(start, rain_speed: 2.0, iterations: 60, rng: Random.new(42))
    current = start
    water = Problem.energy(current).to_f

    iterations.times do |i|
      move = Problem.moves(current).shuffle(random: rng).first
      from_energy = Problem.energy(current)
      candidate = move.energy

      channel =
        if candidate <= from_energy then :current
        elsif candidate <= water then :under_water
        else :rejected
        end

      current = move.trial if channel != :rejected
      water -= rain_speed   # the level drains, squeezing the search upward

      yield i + 1, move, from_energy, current, water, channel
      break if Problem.energy(current) <= 1
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Great Deluge", "local search · Dueck")
  puts "   #{dim('Accept anything above the water level; drain the level every')}"
  puts "   #{dim('iteration. The flood does the scheduling — no temperature, no history.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed) + gray("   water starts at the seed energy"))
  puts

  final = GreatDeluge.search(seed) do |it, move, from_energy, state, water, channel|
    level = format("water %6.1f", water)
    label = case channel
            when :current then sage("beats current")
            when :under_water then gold("under the waterline")
            else coral("above the waterline")
            end
    puts "   #{gray(format('it %-2d', it))} #{bold(format('%-16s', move.description))} " \
         "#{energy_value(from_energy)} #{channel == :rejected ? coral('→') : sage('→')} #{energy_value(Problem.energy(state))}   " \
         "#{label}  #{gray(level)}"
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  ok("as the water drained, only the peak remained above the surface") if Problem.energy(final) <= 1
end
