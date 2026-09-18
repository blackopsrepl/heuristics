# frozen_string_literal: true

# Strongest Fit Decreasing — construction heuristic (scalar assignment)
#
# Best Fit + biggest-tasks-first ordering. The decreasing order removes
# best fit's classic failure mode: a late big task that no tight squeeze
# can hold anymore.
#
# Run me: ruby construction/strongest_fit_decreasing.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module StrongestFitDecreasing
  module_function

  def decreasing_order
    Problem::TASKS.each_index.sort_by { |task| -Problem::TASKS[task] }
  end

  # tightest squeeze among the machines that can hold the task
  def assign(order = decreasing_order)
    assignments = Array.new(Problem::TASKS.size, nil)
    loads = Array.new(Problem::MACHINES.size, 0)

    order.each do |task|
      size = Problem::TASKS[task]
      evaluations = Problem::MACHINES.each_index.map do |m|
        remaining = Problem::MACHINES[m] - (loads[m] + size)
        [m, remaining >= 0, remaining]
      end
      machine = evaluations.select { |_m, fits, _r| fits }
                           .min_by { |_m, _fits, remaining| remaining }
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

  banner("Strongest Fit Decreasing", "construction heuristic · scalar assignment")
  puts "   #{dim('Best Fit in decreasing task order: tight squeezes, big items first.')}"
  puts

  order_line = StrongestFitDecreasing.decreasing_order.map { |t| Problem.task_label(t) }.join("  ")
  step(gray("task order: ") + order_line + gray("   (sorted ↓)"))
  puts

  layout = StrongestFitDecreasing.assign do |task, machine, loads, evaluations|
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

  plain = StrongestFitDecreasing.assign(Problem::TASKS.each_index.to_a)
  plain_note = Problem.complete?(plain) ? "" : coral("   ← #{plain.each_index.select { |t| plain[t].nil? }.map { |t| Problem.task_label(t) }.join(', ')} unplaced")
  puts
  puts "   #{gray('natural order')}  #{score(plain)}#{plain_note}"
  puts "   #{sage('decreasing')}    #{score(layout)}"
  puts
  if !Problem.complete?(plain) && Problem.complete?(layout)
    ok("decreasing order places every task — the natural order cannot")
  else
    note("compare the rows; ordering effects are instance-dependent")
  end
end
