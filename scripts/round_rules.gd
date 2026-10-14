extends RefCounted
class_name DengeRoundRules
## Pure round rules, independent of the room and user interface.
## Players start at 10 points and are eliminated on reaching zero.
## A -1 selection means an already-eliminated player.

const MIN_NUMBER: int = 0
const MAX_NUMBER: int = 100
const TARGET_MULTIPLIER: float = 0.8
const STARTING_SCORE: int = 10
const ELIMINATION_SCORE: int = 0
const EPSILON: float = 0.00001

static func resolve_round(selections: Array[int], current_scores: Array[int]) -> Dictionary:
	if selections.size() != current_scores.size():
		push_error("DENGE: choices and scores must have equal length.")
		return {}

	var sum_of_choices: int = 0
	var active_indices: Array[int] = []
	for i in range(selections.size()):
		if selections[i] == -1:
			continue
		if selections[i] < MIN_NUMBER or selections[i] > MAX_NUMBER:
			push_error("DENGE: selection must be between 0 and 100.")
			return {}
		active_indices.append(i)
		sum_of_choices += selections[i]

	if active_indices.is_empty():
		return {}

	var average: float = float(sum_of_choices) / float(active_indices.size())
	var target: float = average * TARGET_MULTIPLIER
	var minimum_distance: float = INF
	for i in active_indices:
		minimum_distance = minf(minimum_distance, absf(float(selections[i]) - target))

	var winners: Array[int] = []
	var updated_scores: Array[int] = current_scores.duplicate()
	var eliminated_now: Array[int] = []
	for i in active_indices:
		if absf(absf(float(selections[i]) - target) - minimum_distance) < EPSILON:
			winners.append(i)
		else:
			updated_scores[i] = maxi(ELIMINATION_SCORE, updated_scores[i] - 1)
			if updated_scores[i] == ELIMINATION_SCORE and current_scores[i] > ELIMINATION_SCORE:
				eliminated_now.append(i)

	var survivors: Array[int] = []
	for i in range(updated_scores.size()):
		if updated_scores[i] > ELIMINATION_SCORE:
			survivors.append(i)

	return {
		"average": average,
		"target": target,
		"winners": winners,
		"scores": updated_scores,
		"eliminated_now": eliminated_now,
		"survivors": survivors
	}
