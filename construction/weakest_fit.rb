# frozen_string_literal: true

# Weakest Fit — construction heuristic (scalar assignment)
#
# Also known as Worst Fit: place each task into the machine where it
# leaves the MOST room afterwards — keep every machine as loose as
# possible. One pass, O(tasks × machines). The anti-fragile sibling of
# best fit: nothing ends up wedged, at the cost of loose packing.
#
# Run me: ruby construction/weakest_fit.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module WeakestFit
  module_function

  # Returns the assignment array; yields (task, machine, loads, evaluations)
  # where evaluations is [[machine, fits?, remaining_after], …].
  def assign(order = Problem::TASKS.each_index.to_a)
    assignments = Array.new(Problem::TASKS.size, nil)
    loads = Array.new(Problem::MACHINES.size, 0)

    order.each do |task|
      size = Problem::TASKS[task]
      evaluations = Problem::MACHINES.each_index.map do |m|
        remaining = Problem::MACHINES[m] - (loads[m] + size)
        [m, remaining >= 0, remaining]
      end
      machine = evaluations.select { |_m, fits, _r| fits }
                           .max_by { |_m, _fits, remaining| remaining }
                           &.first
      assignments[task] = machine
      loads[machine] += size if machine
      yield task, machine, loads.dup, evaluations if block_given?
    end

    assignments
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("Weakest Fit (Worst Fit)", "construction heuristic · scalar assignment")
  puts "   #{dim('Place each task where it leaves the most room afterwards —')}"
  puts "   #{dim('keep every machine as loose as possible for whatever comes.')}"
  puts

  step(gray("task order: ") + Problem::TASKS.each_index.map { |t| Problem.task_label(t) }.join("  "))
  puts

  layout = WeakestFit.assign do |task, machine, loads, evaluations|
    options = evaluations.select { |_m, fits, _r| fits }
                         .map { |m, _f, r| "#{Problem.machine_label(m)}→#{r} left" }
    verdict = machine ? azure("→ #{Problem.machine_label(machine)}") : coral("→ unassigned!")
    step(format("%-8s %s%s", Problem.task_label(task), verdict,
                options.empty? ? "" : gray("   fits: #{options.join('  ')}")))
    note("loads " + loads.each_with_index
        .select { |load, _i| load.positive? }.map { |load, i| "m#{i + 1}=#{load}" }.join("  "))
  end

  puts
  puts "   #{bold('Final layout')}"
  Problem.loads(layout).each_with_index do |load, m|
    gauge(Problem.machine_label(m), load, Problem::MACHINES[m])
  end
  puts
  puts "   #{score(layout)}"
  if Problem.complete?(layout) && Problem.feasible?(layout)
    ok("loose packing, maximum headroom everywhere")
  else
    unplaced = layout.each_index.select { |t| layout[t].nil? }.map { |t| Problem.task_label(t) }
    miss(unplaced.empty? ? "infeasible layout" : "construction failed: #{unplaced.join(', ')} fit nowhere")
  end
end
