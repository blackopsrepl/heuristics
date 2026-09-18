# frozen_string_literal: true

# First Fit Decreasing — construction heuristic (scalar assignment)
#
# First Fit, but the tasks arrive biggest-first. Sorting is the whole
# trick: big items are hard to place, so they go first while machines
# are empty, and small items slide into the gaps afterwards. Classic
# result from bin packing: decreasing the order turns a naive pass into
# a strong heuristic.
#
# Run me: ruby construction/first_fit_decreasing.rb

require_relative "../lib/style"
require_relative "../lib/problem"

module FirstFitDecreasing
  module_function

  # tasks sorted by size, largest first
  def decreasing_order
    Problem::TASKS.each_index.sort_by { |task| -Problem::TASKS[task] }
  end

  # same placement rule as First Fit: first machine with room
  def assign(order = decreasing_order)
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

  banner("First Fit Decreasing", "construction heuristic · scalar assignment")
  puts "   #{dim('First Fit, but biggest tasks go first: hard items while machines')}"
  puts "   #{dim('are still empty, small items fill the gaps later.')}"
  puts

  order_line = FirstFitDecreasing.decreasing_order.map { |t| Problem.task_label(t) }.join("  ")
  step(gray("task order: ") + order_line + gray("   (sorted ↓)"))
  puts

  layout = FirstFitDecreasing.assign do |task, machine, loads, attempts|
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

  plain = FirstFitDecreasing.assign(Problem::TASKS.each_index.to_a)
  plain_note = Problem.complete?(plain) ? "" : coral("   ← t4(7) unplaced!")
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
