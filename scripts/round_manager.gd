extends Node

signal round_cleared(round_number: int)
signal round_failed
signal game_won
signal game_over

const MAX_ROUNDS = 6

var game_state: GameState

func setup(gs: GameState) -> void:
	game_state = gs

func check_after_spin() -> void:
	if game_state.is_round_clear():
		if game_state.round_number >= MAX_ROUNDS:
			emit_signal("game_won")
		else:
			emit_signal("round_cleared", game_state.round_number)
	elif game_state.is_busted():
		if game_state.gold <= 0:
			emit_signal("game_over")
		else:
			emit_signal("round_failed")

func advance() -> void:
	game_state.advance_round()

func is_boss_round() -> bool:
	return game_state.round_number == MAX_ROUNDS
