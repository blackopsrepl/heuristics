# frozen_string_literal: true

# First Fit — construction heuristic (scalar assignment)
#
# Walk the tasks in the given order and drop each into the FIRST machine
# that still has room. One pass, no lookahead: O(tasks × machines).
# Blind and fast — the quality lives or dies with the task order, which
# is exactly what first_fit_decreasing exploits.
#
# Run me: ruby construction/first_fit.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module FirstFit
  module_function

  # Returns the assignment array; yields (task, machine, loads, attempts)
  # after each placement for demos. `attempts` is [[machine, fits?], …].
  def assign(order = Problem::TASKS.each_index.to_a)
    assignments = Array.new(Problem::TASKS.size, nil)
    loads = Array.new(Problem::MACHINES.size, 0)

    order.each do |task|
      size = Problem::TASKS[task]
      attempts = []
      machine = Problem::MACHINES.each_index.find do |m|
        fits = loads[m] + size <= Problem::MACHINES[m]
        attempts << [m, fits]
        fits
      end
      assignments[task] = machine
      loads[machine] += size if machine
      yield task, machine, loads.dup, attempts if block_given?
    end

    assignments
  end
end

if __FILE__ == $PROGRAM_NAME
  include Style

  banner("First Fit", "construction heuristic · scalar assignment")
  puts "   #{dim('Walk the tasks in order; drop each into the first machine with room.')}"
  puts "   #{dim('One pass, no lookahead. Quality depends entirely on the task order.')}"
  puts

  step(gray("task order: ") + Problem::TASKS.each_index.map { |t| Problem.task_label(t) }.join("  "))
  puts

  layout = FirstFit.assign do |task, machine, loads, attempts|
    rejected = attempts.reject { |_m, fits| fits }.map { |m, _f| Problem.machine_label(m) }
    verdict = machine ? azure("→ #{Problem.machine_label(machine)}") : coral("→ unassigned!")
    skipped = rejected.empty? ? "" : gray("   (#{rejected.join(', ')} no room)")
    step(format("%-8s %s%s", Problem.task_label(task), verdict, skipped))
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
  if Problem.complete?(layout)
    ok("all tasks placed") if Problem.feasible?(layout)
  else
    unplaced = layout.each_index.select { |t| layout[t].nil? }.map { |t| Problem.task_label(t) }
    miss("construction failed: #{unplaced.join(', ')} fit nowhere in this order")
  end
end
