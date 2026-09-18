# frozen_string_literal: true

# List K-Opt (2-opt) — route improvement heuristic
#
# Construction heuristics leave crossings and detours; improvement
# heuristics iron them out. 2-opt is the classic: pick two positions,
# reverse the segment between them, keep the change if the route gets
# shorter, repeat until no reversal helps. Each full pass is
# O(n²) evaluations; the loop repeats until a local optimum.
#
# Run me: ruby construction/list_k_opt.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module ListKOpt
  module_function

  # Repeated 2-opt; yields (pass, i, j, before, after, gain) for each
  # accepted reversal. Returns [best_route, history].
  def improve(route)
    best = route.dup
    history = []
    pass = 0

    loop do
      improved = false
      (0...(best.length - 1)).each do |i|
        ((i + 1)...best.length).each do |j|
          candidate = best[0...i] + best[i..j].reverse + best[(j + 1)..]
          gain = Problem.route_cost(best) - Problem.route_cost(candidate)
          next unless gain.positive?
          history << { pass: pass, i: i, j: j, before: best.dup, after: candidate, gain: gain }
          yield pass, i, j, best.dup, candidate.dup, gain if block_given?
          best = candidate
          improved = true
        end
      end
      break unless improved
      pass += 1
    end

    [best, history]
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("List K-Opt (2-opt)", "route improvement")
  puts "   #{dim('Reverse segments while it shortens the route; stop when no')}"
  puts "   #{dim('reversal helps. Construction made it valid — improvement makes it good.')}"
  puts

  given = [1, 3, 2, 4]
  step(gray("given route:"))
  route_line(given)
  puts

  best, = ListKOpt.improve(given) do |pass, i, j, before, after, gain|
    step(format("pass %d · reverse positions %d..%d   −%d cost", pass, i, j, gain))
    note("was: [#{before.join(' ')}]")
    route_line(after)
  end

  puts
  step(gray("final:"))
  route_line(best)
  puts
  puts "   #{gray('given')}   #{bold(Problem.route_cost(given))}"
  puts "   #{sage('2-opt')}   #{bold(Problem.route_cost(best))}"
  puts
  ok("no remaining segment reversal shortens the route — a 2-opt local optimum")
end
