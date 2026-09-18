# frozen_string_literal: true

# Late Acceptance — local search metaheuristic (Burke & Bykov)
#
# Accept a candidate when it beats the current state — or when it beats
# the state from N iterations ago, kept in a circular history buffer.
# The buffer is a soft memory of the recent past: moving somewhere the
# search has already outgrown feels pointless, so the comparison guides
# the walk without a temperature to tune.
#
# Neighborhood: reassign one task or exchange two (the full move set).
#
# Run me: ruby local_search/late_acceptance.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module LateAcceptance
  module_function

  # Yields (iteration, move, from_energy, current, channel, history) per step.
  def search(start, history_size: 3, iterations: 25, rng: Random.new(42))
    current = start
    history = Array.new(history_size, Problem.energy(current))
    pointer = 0

    iterations.times do |i|
      from_energy = Problem.energy(current)

      # evaluate shuffled candidates until one is accepted
      channel = :rejected
      move = nil
      Problem.moves(current).shuffle(random: rng).each do |candidate_move|
        move = candidate_move
        candidate = move.energy
        channel =
          if candidate <= from_energy then :current
          elsif candidate <= history[pointer] then :history
          else :rejected
          end
        break unless channel == :rejected
      end

      if channel != :rejected
        history[pointer] = from_energy   # remember the state we are leaving
        pointer = (pointer + 1) % history_size
        current = move.trial
      end

      yield i + 1, move, from_energy, current, channel, history.dup
      break if Problem.energy(current) <= 1
    end

    current
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Late Acceptance", "local search · Burke & Bykov")
  puts "   #{dim('Accept a move that beats the present — or that beats where the')}"
  puts "   #{dim('search was N iterations ago. A history buffer as soft memory.')}"
  puts

  seed = Problem::SEED
  step(gray("seed: [#{seed.join(' ')}]  ") + energy(seed))
  puts

  final = LateAcceptance.search(seed) do |it, move, from_energy, state, channel, history|
    buffer = "[#{history.map { |e| format('%3d', e) }.join(' ')}]"
    label = case channel
            when :current then sage("beats current")
            when :history then gold("beats history — late acceptance")
            else coral("rejected")
            end
    puts "   #{gray(format('it %-2d', it))} #{bold(format('%-16s', move.description))} " \
         "#{energy_value(from_energy)} #{channel == :rejected ? coral('→') : sage('→')} #{energy_value(Problem.energy(state))}   " \
         "#{label}  #{gray('buf')} #{gray(buffer)}"
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(final).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{energy(final)}   #{score(final)}"
  puts
  ok("the history comparison opened the path the current could not") if Problem.energy(final) <= 1
end
