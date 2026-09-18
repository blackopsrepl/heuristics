# frozen_string_literal: true

# Clarke-Wright Savings — construction heuristic (routing)
#
# Start with every stop on its own depot-to-depot shuttle, then merge
# greedily. The savings of connecting stops a and b directly is
# s(a,b) = d(depot,a) + d(depot,b) − d(a,b): the detour eliminated by
# joining them. Process the savings largest-first and merge whenever the
# pair is end-to-end on two different routes and capacity allows.
# The classic 1964 algorithm for vehicle routing.
#
# Run me: ruby construction/list_clarke_wright.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module ListClarkeWright
  DEMANDS  = { 1 => 2, 2 => 2, 3 => 1, 4 => 1 }   # stop => demand
  CAPACITY = 4                                     # per-vehicle demand limit

  module_function

  def demand(route) = route.sum { |stop| DEMANDS[stop] }

  def savings_table
    Problem::STOPS.keys.combination(2).map { |a, b|
      [Problem.distance(0, a) + Problem.distance(0, b) - Problem.distance(a, b), a, b]
    }.sort_by { |s, _a, _b| -s }
  end

  # Merges shuttles greedily; yields (savings, a, b, verdict, routes).
  # verdict is :merge, :capacity, or :not_endpoints.
  def build_routes
    routes = Problem::STOPS.keys.map { |stop| [stop] }

    savings_table.each do |savings, a, b|
      left  = routes.find { |route| route.last == a }
      right = routes.find { |route| route.first == b }

      verdict =
        if left.nil? || right.nil? || left.equal?(right)
          :not_endpoints
        elsif demand(left) + demand(right) > CAPACITY
          :capacity
        else
          left.concat(right)
          routes.delete(right)
          :merge
        end
      yield savings, a, b, verdict, routes.map(&:dup) if block_given?
    end

    routes
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Clarke-Wright Savings", "construction heuristic · routing")
  puts "   #{dim('s(a,b) = d(0,a) + d(0,b) − d(a,b)  — the detour saved by linking a and b.')}"
  puts "   #{dim('Merge shuttles largest-savings first, capacity permitting.')}"
  puts
  puts "   #{gray('demands')}  #{ListClarkeWright::DEMANDS.map { |s, d| "stop#{s}:#{d}" }.join('  ')}   #{gray('vehicle capacity')} #{ListClarkeWright::CAPACITY}"
  puts

  table_line = ListClarkeWright.savings_table.map { |s, a, b| "s(#{a},#{b})=#{s}" }.join("  ")
  step(gray("savings table (sorted ↓): ") + table_line)
  puts

  routes = ListClarkeWright.build_routes do |savings, a, b, verdict, current|
    label = case verdict
            when :merge then sage("merge ✓")
            when :capacity then coral("over capacity")
            else gray("not end-to-end")
            end
    step(format("s(%d,%d)=%-2d  %s", a, b, savings, label))
    current.each_with_index do |r, i|
      note("route #{i + 1}: #{r.join(' ')}   #{gray("demand #{ListClarkeWright.demand(r)}")}")
    end
  end

  puts
  puts "   #{bold('Final routes')}"
  total = 0
  routes.each_with_index do |r, i|
    route_line(r)
    total += Problem.route_cost(r)
  end

  shuttles = Problem::STOPS.keys.map { |stop| [stop] }
  baseline = shuttles.sum { |r| Problem.route_cost(r) }
  puts
  puts "   #{gray('pure shuttles')}   #{bold(baseline)}"
  puts "   #{sage('after merging')}    #{bold(total)}"
  puts
  ok("merging consumed the largest savings the capacity allowed") if total < baseline
end
