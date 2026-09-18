# frozen_string_literal: true

# List Round Robin — construction heuristic (routing)
#
# Deal the stops to a fixed number of routes like cards: one for route
# one, one for route two, wrap around, repeat. No costs are consulted at
# all — the point is a fast, perfectly balanced split that insertion
# heuristics or local search can improve afterwards. O(stops).
#
# Run me: ruby construction/list_round_robin.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module ListRoundRobin
  module_function

  # Deals stops round-robin; yields (stop, route_index, routes) per deal.
  def deal(stops = Problem::STOPS.keys, routes: 2)
    table = Array.new(routes) { [] }
    stops.each_with_index do |stop, index|
      target = index % routes
      table[target] << stop
      yield stop, target, table.map(&:dup) if block_given?
    end
    table
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("List Round Robin", "construction heuristic · routing")
  puts "   #{dim('Deal stops to routes like cards: one each, wrap around, repeat.')}"
  puts "   #{dim('Zero cost evaluations — balance by construction, not by search.')}"
  puts

  routes = ListRoundRobin.deal do |stop, target, current|
    step(format("stop %d  →  route %d", stop, target + 1))
    current.each_with_index do |r, i|
      note("route #{i + 1}: #{r.empty? ? gray('—') : azure(r.join(' '))}")
    end
  end

  puts
  puts "   #{bold('Final routes')}"
  total = 0
  routes.each_with_index do |r, i|
    route_line(r)
    total += Problem.route_cost(r)
  end

  one_big = Problem::STOPS.keys
  puts
  puts "   #{gray('one single route')}  #{bold(Problem.route_cost(one_big))}"
  puts "   #{sage('round robin ×2')}    #{bold(total)}   #{gray('(balance is bought with extra depot returns)')}"
  puts
  ok("perfectly even deal — cost was never consulted")
end
