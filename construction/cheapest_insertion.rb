# frozen_string_literal: true

# Cheapest Insertion — construction heuristic (routing)
#
# Start with a stub route and grow it: among every unplaced stop and
# every position, repeatedly splice in the (stop, position) pair with
# the smallest cost increase. Each round is O(stops × positions), the
# whole construction O(n³) on n stops — trivial at this size, and every
# decision is a number you can check by hand.
#
# Run me: ruby construction/cheapest_insertion.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module CheapestInsertion
  module_function

  # Grows one route from a seed stop; yields (round, route, best, deltas)
  # after each insertion. deltas maps stop => [[pos, delta], …].
  def build_route(seed_stop: 1)
    route = [seed_stop]
    remaining = Problem::STOPS.keys - route
    round = 0

    until remaining.empty?
      deltas = remaining.to_h { |stop|
        [stop, (0..route.length).map { |pos| [pos, Problem.insertion_delta(route, stop, pos)] }]
      }
      best_stop, positions = deltas.min_by { |_stop, pos_deltas| pos_deltas.min_by(&:last).last }
      best_pos, best_delta = positions.min_by(&:last)
      route.insert(best_pos, best_stop)
      remaining.delete(best_stop)
      round += 1
      yield round, route.dup, { stop: best_stop, pos: best_pos, delta: best_delta }, deltas if block_given?
    end

    route
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Cheapest Insertion", "construction heuristic · routing")
  puts "   #{dim('Grow one route: every round, splice in the stop at the position')}"
  puts "   #{dim('with the smallest cost increase, until nobody is left outside.')}"
  puts

  step(gray("seed route: "))
  route_line([1])

  route = CheapestInsertion.build_route do |round, current, best, deltas|
    puts
    step(bold("round #{round}") + gray(" — insertion deltas"))
    deltas.each do |stop, positions|
      rows = positions.map do |pos, delta|
        mark = stop == best[:stop] && pos == best[:pos]
        body = "pos#{pos}: +#{delta}"
        mark ? bold(sage(body)) : gray(body)
      end
      puts "       #{gray("stop #{stop}")}  #{rows.join('   ')}"
    end
    chosen = "insert stop #{best[:stop]} at position #{best[:pos]}  (+#{best[:delta]})"
    puts "       #{sage('→')} #{chosen}"
    step("route now:")
    route_line(current)
  end

  puts
  step(gray("final:"))
  route_line(route)

  naive = Problem::STOPS.keys
  puts
  puts "   #{gray('stop-id order')}   #{bold(Problem.route_cost(naive))}"
  puts "   #{sage('cheapest ins.')}   #{bold(Problem.route_cost(route))}"
  puts
  ok("every splice was the cheapest available at the time") if Problem.route_cost(route) <= Problem.route_cost(naive)
end
