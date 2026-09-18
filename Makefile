# Heuristics Laboratory
#
# Pure Ruby, zero dependencies. `make` runs everything.

RUBY ?= ruby

CONSTRUCTION_ALGOS := first_fit first_fit_decreasing strongest_fit strongest_fit_decreasing \
                      weakest_fit weakest_fit_decreasing cheapest_insertion list_round_robin \
                      list_regret_insertion list_clarke_wright list_k_opt
LOCAL_SEARCH_ALGOS := hill_climbing step_counting_hill_climbing tabu_search simulated_annealing \
                      late_acceptance diversified_late_acceptance great_deluge \
                      variable_neighborhood_descent

.PHONY: all help list construction local-search $(CONSTRUCTION_ALGOS) $(LOCAL_SEARCH_ALGOS)

.DEFAULT_GOAL := help

all: construction local-search

help: list

list:
	@printf "\n── construction heuristics ──────────────────────────\n"
	@printf "  make %-34s # %s\n" "first_fit" "first machine with room"
	@printf "  make %-34s # biggest tasks first\n" "first_fit_decreasing"
	@printf "  make %-34s # best fit: tightest squeeze\n" "strongest_fit"
	@printf "  make %-34s # best fit, decreasing order\n" "strongest_fit_decreasing"
	@printf "  make %-34s # worst fit: loosest machine\n" "weakest_fit"
	@printf "  make %-34s # worst fit, decreasing order\n" "weakest_fit_decreasing"
	@printf "  make %-34s # TSP: cheapest splice each round\n" "cheapest_insertion"
	@printf "  make %-34s # deal stops like cards\n" "list_round_robin"
	@printf "  make %-34s # most-to-lose stop goes first\n" "list_regret_insertion"
	@printf "  make %-34s # Clarke-Wright savings merges\n" "list_clarke_wright"
	@printf "  make %-34s # 2-opt segment reversals\n" "list_k_opt"
	@printf "\n── local search metaheuristics ──────────────────────\n"
	@printf "  make %-34s # steepest descent (gets trapped)\n" "hill_climbing"
	@printf "  make %-34s # side steps with a counter budget\n" "step_counting_hill_climbing"
	@printf "  make %-34s # forbidden reversals, aspiration\n" "tabu_search"
	@printf "  make %-34s # Metropolis acceptance, cooling\n" "simulated_annealing"
	@printf "  make %-34s # beat the state from N steps ago\n" "late_acceptance"
	@printf "  make %-34s # late acceptance + tolerance band\n" "diversified_late_acceptance"
	@printf "  make %-34s # accept above a draining waterline\n" "great_deluge"
	@printf "  make %-34s # switch neighborhoods when stuck\n" "variable_neighborhood_descent"
	@printf "\n"

construction: $(CONSTRUCTION_ALGOS)

local-search: $(LOCAL_SEARCH_ALGOS)

$(CONSTRUCTION_ALGOS):
	@$(RUBY) construction/$@.rb

$(LOCAL_SEARCH_ALGOS):
	@$(RUBY) local_search/$@.rb
