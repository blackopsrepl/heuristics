# frozen_string_literal: true

# List Regret Insertion — construction heuristic (routing)
#
# Cheapest insertion, but with foresight: instead of asking "which
# insertion is cheapest right now?", ask "which stop would suffer most
# from being postponed?". That suffering is the regret — the gap
# between a stop's best and second-best insertion. Insert the stop with
# the largest regret first; cheap-to-place-anywhere stops can wait.
# Each round costs O(stops² × positions).
#
# Run me: ruby construction/list_regret_insertion.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module ListRegretInsertion
  module_function

  # every (route, position) insertion option for one stop
  def placements(stop, routes)
    options = []
    routes.each_index do |r|
      (0..routes[r].length).each do |pos|
        options << { route: r, pos: pos, delta: Problem.insertion_delta(routes[r], stop, pos) }
      end
    end
    options.sort_by { |option| option[:delta] }
  end

  # Builds a fleet of routes; yields (round, table, chosen) per round,
  # where table maps stop => {regret:, best:} and chosen is the winner.
  def build_routes(route_count: 2)
    routes = Array.new(route_count) { [] }
    remaining = Problem::STOPS.keys
    round = 0

    until remaining.empty?
      table = remaining.to_h { |stop|
        sorted = placements(stop, routes)
        best = sorted.first
        second = sorted[1] || best
        [stop, { regret: second[:delta] - best[:delta], best: best }]
      }
      chosen_stop, chosen = table.max_by { |_stop, row| [row[:regret], -row[:best][:delta]] }
      target = chosen[:best]
      routes[target[:route]].insert(target[:pos], chosen_stop)
      remaining.delete(chosen_stop)
      round += 1
      yield round, routes.map(&:dup), table, chosen_stop, target if block_given?
    end

    routes
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("List Regret Insertion", "construction heuristic · routing")
  puts "   #{dim('Insert the stop with the largest REGRET — the gap between its')}"
  puts "   #{dim('best and second-best placement. Urgent stops go first.')}"
  puts

  routes = ListRegretInsertion.build_routes do |round, current, table, chosen_stop, target|
    step(bold("round #{round}") + gray(" — regret per stop"))
    table.each do |stop, row|
      mark = stop == chosen_stop
      line = format("stop %d  regret %d   best: route %d pos %d (+%d)",
                    stop, row[:regret], row[:best][:route] + 1, row[:best][:pos], row[:best][:delta])
      puts "       #{mark ? bold(sage(line)) : gray(line)}"
    end
    puts "       #{sage('→')} insert stop #{chosen_stop} into route #{target[:route] + 1} at position #{target[:pos]}"
    step("routes now:")
    current.each_with_index do |r, i|
      next if r.empty?
      route_line(r)
    end
  end

  puts
  puts "   #{bold('Final routes')}"
  total = 0
  routes.reject(&:empty?).each_with_index do |r, _i|
    route_line(r)
    total += Problem.route_cost(r)
  end
  puts
  puts "   #{gray('fleet total')}  #{bold(total)}"
  puts
  ok("every insertion maximized regret — postponement made expensive")
end
