# frozen_string_literal: true

# The shared toy problems every demo works on, kept tiny so each named
# algorithm can be followed end to end.
#
#   * Scalar problem: pack four compile tasks onto three capacity-limited
#     machines. Feasibility (no overloaded machine) dominates balance.
#   * Route problem: one depot (node 0) and four stops on a straight line.
#     The line metric keeps every distance computable by eye.
#
# Pure Ruby, no gems, no I/O — just the model and the math.
module Problem
  TASKS = [6, 2, 4, 7]              # task sizes, one entry per task t1..t4
  MACHINES = [8, 7, 6]              # machine capacities, one entry per machine m1..m3

  SEED = [0, 0, 1, 2]               # overloaded starting assignment for local search

  STOPS = { 1 => 2, 2 => 5, 3 => 9, 4 => 12 }   # stop id => position on the line

  module_function

  def task_label(task) = format("t%d(%d)", task + 1, TASKS[task])
  def machine_label(machine) = format("m%d[%d]", machine + 1, MACHINES[machine])
  def move_label(task, from, to) = "#{task_label(task)} #{format('m%d→m%d', from + 1, to + 1)}"

  def loads(assignments)
    totals = Array.new(MACHINES.size, 0)
    assignments.each_with_index do |machine, task|
      next if machine.nil?
      totals[machine] += TASKS[task]
    end
    totals
  end

  # false when any task was left unplaced by a construction heuristic
  def complete?(assignments)
    assignments.all? { |machine| !machine.nil? }
  end

  # total size parked on machines beyond their capacity
  def overload(assignments)
    loads(assignments).zip(MACHINES).sum { |total, capacity| [0, total - capacity].max }
  end

  # spread between the busiest and the quietest machine
  def imbalance(assignments)
    totals = loads(assignments)
    totals.max - totals.min
  end

  # lexicographic score as arrays: fix overload first, balance second.
  # Compared with Array#<=>, so more-negative is better.
  def score(assignments)
    [-overload(assignments), -imbalance(assignments)]
  end

  # scalar energy for the metaheuristics: overload dominates by weight
  def energy(assignments)
    100 * overload(assignments) + imbalance(assignments)
  end

  def feasible?(assignments)
    overload(assignments).zero?
  end

  # ── route helpers ──

  def position(node) = node.zero? ? 0 : STOPS[node]

  def distance(a, b) = (position(a) - position(b)).abs

  # depot → stops… → depot
  def route_cost(route)
    path = [0] + route + [0]
    path.each_cons(2).sum { |a, b| distance(a, b) }
  end

  # cost change of splicing stop into route at position pos
  def insertion_delta(route, stop, pos)
    route_cost(route[...pos] + [stop] + route[pos..]) - route_cost(route)
  end

  # ── the shared local-search neighborhood ──
  #
  # Deliberately minimal: the metaheuristics in local_search/ are the
  # stars, the neighborhood is scenery. Two move families — reassign one
  # task, or exchange the machines of two tasks. On this instance the
  # change moves alone run into a local optimum at energy 101; the swap
  # moves are the way out, which is what makes the metaheuristics
  # behave differently from one another.

  Move = Struct.new(:description, :trial, :score, :energy, :kind)

  def change_moves(assignments)
    moves = []
    assignments.each_index do |task|
      (0...MACHINES.size).each do |machine|
        next if machine == assignments[task]
        trial = assignments.dup
        trial[task] = machine
        moves << Move.new(move_description(assignments, trial), trial, score(trial),
                          energy(trial), :change)
      end
    end
    moves
  end

  def swap_moves(assignments)
    moves = []
    assignments.each_index do |a|
      ((a + 1)...assignments.size).each do |b|
        next if assignments[a] == assignments[b]
        trial = assignments.dup
        trial[a], trial[b] = trial[b], trial[a]
        moves << Move.new(move_description(assignments, trial), trial, score(trial),
                          energy(trial), :swap)
      end
    end
    moves
  end

  # the full neighborhood every metaheuristic may use
  def moves(assignments)
    change_moves(assignments) + swap_moves(assignments)
  end

  # describe the edit between two assignments that differ in one slot (change)
  # or two slots (swap), as "t3(2) m2→m3" / "t1(4)⇄t4(3)"
  def move_description(before, after)
    changed = before.each_index.select { |i| before[i] != after[i] }
    if changed.one?
      task = changed.first
      move_label(task, before[task], after[task])
    else
      a, b = changed
      "#{task_label(a)}⇄#{task_label(b)}"
    end
  end
end
