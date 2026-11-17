# heuristics

Classic construction heuristics and local-search metaheuristics, each in
one readable, runnable Ruby file. You need Ruby and nothing else. Every demo
prints its decisions step by step so you can check the arithmetic by eye.

## The shared toy problems

Two tiny instances carry every demo:

**Scalar assignment.** Pack four tasks of sizes 6, 2, 4, 7 onto three
machines with capacities 8, 7, 6. Feasibility (no machine overloaded)
dominates balance (spread between the busiest and quietest machine).
Construction heuristics build an assignment from scratch; local search
starts from the overloaded seed `[0, 0, 1, 2]` (energy 104, where energy
is `100 × overload + imbalance`). Naive orders fail to place the 7-task,
single reassignments get stuck in a local optimum at energy 101, and each
metaheuristic escapes it its own way, down to energy 1.

**Routing.** One depot (node 0) and four stops on a straight line at
positions 2, 5, 9, 12. On a line you can check every distance and delta
in your head.

## Run

```bash
make                    # this menu
make all                # every algorithm
make construction       # the construction heuristics
make local-search       # the metaheuristics
make tabu_search        # one algorithm
ruby local_search/tabu_search.rb    # or run a file directly
```

## The matrix

| File | Idea | Outcome on the toy instance |
|------|------|------------------------------|
| `construction/first_fit.rb` | first machine with room | t4(7) fits nowhere, construction fails |
| `construction/first_fit_decreasing.rb` | biggest tasks first | places everything, imbalance 1 |
| `construction/strongest_fit.rb` | best fit: tightest squeeze | optimal balance 7/6/6 |
| `construction/strongest_fit_decreasing.rb` | best fit, decreasing | same quality, different route |
| `construction/weakest_fit.rb` | worst fit: loosest machine | t4(7) stranded again |
| `construction/weakest_fit_decreasing.rb` | worst fit, decreasing | optimal balance 7/6/6 |
| `construction/cheapest_insertion.rb` | splice the cheapest (stop, position) each round | cost 24, optimal on a line |
| `construction/list_round_robin.rb` | deal stops like cards | perfect balance, zero cost checks |
| `construction/list_regret_insertion.rb` | insert the most-to-lose stop first | regret-driven, costs computed live |
| `construction/list_clarke_wright.rb` | merge shuttles by savings s(a,b) | 56 → 28 under capacity 4 |
| `construction/list_k_opt.rb` | reverse segments while it helps | 32 → 24, a 2-opt local optimum |
| `local_search/hill_climbing.rb` | steepest descent, change moves only | stuck at 101 |
| `local_search/step_counting_hill_climbing.rb` | side steps on a counter budget | escapes to 1 |
| `local_search/tabu_search.rb` | forbidden reversals + aspiration | escapes to 1 |
| `local_search/simulated_annealing.rb` | accept worse with exp(−Δ/T), cooling | escapes to 1 |
| `local_search/late_acceptance.rb` | beat the state from N steps ago | escapes to 1 |
| `local_search/diversified_late_acceptance.rb` | + tolerance band around the best | escapes to 1 |
| `local_search/great_deluge.rb` | accept above a draining waterline | escapes to 1 |
| `local_search/variable_neighborhood_descent.rb` | N1 stuck → switch to N2 | swap rescues descent, 1 |

Hill climbing gets stuck where every other file gets out, on the same
instance and seed, and each file shows the mechanism that gets it out.

## Layout

```text
lib/style.rb      ANSI colors, banners, gauges, trace lines
lib/problem.rb    the two toy instances, scoring, the shared neighborhood
construction/     one self-contained file per construction heuristic
local_search/     one self-contained file per metaheuristic
```

Randomized demos seed their own `Random.new(42)` and say so, so every run
prints the same thing.
