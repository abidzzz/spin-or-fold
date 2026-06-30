class_name GameState

signal gold_changed(new_gold: int)
signal score_changed(new_score: int)
signal bet_amount_changed(new_bet: int)
signal round_changed(new_round: int)

const STARTING_GOLD = 100
const BASE_BET_AMOUNT = 10

var gold: int = STARTING_GOLD
var score: int = 0
var current_bet: HandEvaluator.Hand = HandEvaluator.Hand.PAIR
var round_number: int = 1
var hands_left: int = 5
var target_score: int = 100
var win_streak: int = 0
var bet_amount: int = BASE_BET_AMOUNT

# Roguelike stats
var total_runs: int = 0
var total_wins: int = 0
var best_run: int = 0
var total_gold_earned_all_time: int = 0

# Stats tracking for current run
var total_spins: int = 0
var total_wins_this_run: int = 0
var total_losses_this_run: int = 0
var best_hand: HandEvaluator.Hand = HandEvaluator.Hand.HIGH_CARD
var highest_streak: int = 0

func place_bet(hand: HandEvaluator.Hand) -> void:
	current_bet = hand
	bet_amount = BASE_BET_AMOUNT + (round_number - 1) * 2
	bet_amount_changed.emit(bet_amount)

func resolve_spin(result_hand: HandEvaluator.Hand) -> Dictionary:
	hands_left -= 1
	total_spins += 1
	
	var won = result_hand >= current_bet
	var multiplier = HandEvaluator.get_hand_multiplier(result_hand)
	var payout = 0
	var hand_score = 0
	var hand_bonus = 0
	var streak_score_bonus = 0
	var perfect_hand_bonus = 0
	
	if result_hand > best_hand:
		best_hand = result_hand

	if won:
		total_wins_this_run += 1
		win_streak += 1
		if win_streak > highest_streak:
			highest_streak = win_streak
		
		var base_payout = bet_amount * multiplier
		var streak_bonus = min(win_streak * 2, 20)
		payout = base_payout + streak_bonus
		
		var base_score = bet_amount * multiplier * 2
		
		match result_hand:
			HandEvaluator.Hand.PAIR:
				hand_bonus = 5
			HandEvaluator.Hand.TWO_PAIR:
				hand_bonus = 15
			HandEvaluator.Hand.THREE_OF_A_KIND:
				hand_bonus = 30
			HandEvaluator.Hand.STRAIGHT:
				hand_bonus = 50
			HandEvaluator.Hand.FLUSH:
				hand_bonus = 70
			HandEvaluator.Hand.FULL_HOUSE:
				hand_bonus = 100
			HandEvaluator.Hand.FOUR_OF_A_KIND:
				hand_bonus = 150
			HandEvaluator.Hand.STRAIGHT_FLUSH:
				hand_bonus = 250
			HandEvaluator.Hand.ROYAL_FLUSH:
				hand_bonus = 500
		
		streak_score_bonus = win_streak * 5
		
		if hands_left == 0 and win_streak >= 5:
			perfect_hand_bonus = 50
		
		hand_score = base_score + hand_bonus + streak_score_bonus + perfect_hand_bonus
		
		gold += payout
		score += hand_score
		total_gold_earned_all_time += payout
		
	else:
		total_losses_this_run += 1
		win_streak = 0
		
		var consolation_score = 2
		if result_hand == HandEvaluator.Hand.HIGH_CARD:
			consolation_score = 1
		elif result_hand >= HandEvaluator.Hand.PAIR and result_hand < current_bet:
			consolation_score = 3
		
		hand_score = consolation_score
		
		var gold_penalty = bet_amount / 2
		if round_number >= 4:
			gold_penalty = bet_amount / 3
		gold -= int(gold_penalty)
		gold = max(gold, 0)
		
		score += hand_score

	gold_changed.emit(gold)
	score_changed.emit(score)

	return {
		"won": won,
		"result_hand": result_hand,
		"result_name": HandEvaluator.get_hand_name(result_hand),
		"payout": payout,
		"multiplier": multiplier,
		"streak": win_streak if won else 0,
		"hand_score": hand_score,
		"hand_bonus": hand_bonus,
		"streak_bonus": streak_score_bonus,
		"perfect_bonus": perfect_hand_bonus,
		"gold": gold,
		"score": score,
		"hands_left": hands_left,
		"target_score": target_score,
		"is_round_clear": score >= target_score,
		"bet_amount": bet_amount
	}

func is_round_clear() -> bool:
	return score >= target_score

func is_busted() -> bool:
	return hands_left <= 0 and score < target_score

func advance_round() -> void:
	round_number += 1
	hands_left = 5
	target_score = int(target_score * 1.7)
	score = 0
	win_streak = 0
	round_changed.emit(round_number)

func is_boss_round() -> bool:
	return round_number == 6

# --- HARDER BOSS ROUND ---
func resolve_boss_spin(result_hand: HandEvaluator.Hand) -> Dictionary:
	# BOSS ROUND: Must get at least a PAIR to win
	# The bet is automatically set to PAIR (minimum)
	# But the player needs a BETTER hand to win big
	
	var required_hand = HandEvaluator.Hand.PAIR  # Minimum to survive
	var won = result_hand >= required_hand
	
	var payout = 0
	var hand_score = 0
	
	if won:
		total_wins_this_run += 1
		
		# Payout based on how good the hand is
		var multiplier = HandEvaluator.get_hand_multiplier(result_hand)
		var base_payout = gold * 0.5  # 50% of current gold as base
		payout = int(base_payout * (multiplier / 2.0))  # Bigger multiplier = bigger payout
		payout = max(payout, 10)  # Minimum payout
		
		gold += payout
		score = target_score  # Instant clear
		total_gold_earned_all_time += payout
		hand_score = 50  # Boss bonus points
		
	else:
		total_losses_this_run += 1
		
		# Lose ALL gold on boss failure (hardcore!)
		gold = 0
		score = 0
		payout = 0
		hand_score = 0

	gold_changed.emit(gold)
	score_changed.emit(score)

	return {
		"won": won,
		"result_hand": result_hand,
		"result_name": HandEvaluator.get_hand_name(result_hand),
		"gold": gold,
		"score": score,
		"hands_left": hands_left,
		"payout": payout,
		"hand_score": hand_score,
		"is_boss": true,
		"required_hand": "PAIR"
	}

# --- Stats functions ---
func get_stats() -> Dictionary:
	return {
		"total_runs": total_runs,
		"total_wins": total_wins,
		"best_run": best_run,
		"total_gold_earned": total_gold_earned_all_time,
		"current_run_wins": total_wins_this_run,
		"current_run_losses": total_losses_this_run,
		"current_run_spins": total_spins,
		"current_run_best_hand": HandEvaluator.get_hand_name(best_hand),
		"current_run_highest_streak": highest_streak
	}

func reset_for_new_run() -> void:
	total_runs += 1
	if round_number > best_run:
		best_run = round_number
	
	gold = STARTING_GOLD
	score = 0
	round_number = 1
	hands_left = 5
	target_score = 100
	win_streak = 0
	bet_amount = BASE_BET_AMOUNT
	
	total_spins = 0
	total_wins_this_run = 0
	total_losses_this_run = 0
	best_hand = HandEvaluator.Hand.HIGH_CARD
	highest_streak = 0
	
	round_changed.emit(round_number)
	gold_changed.emit(gold)
	score_changed.emit(score)

func get_hand_score(hand: HandEvaluator.Hand) -> int:
	match hand:
		HandEvaluator.Hand.HIGH_CARD:
			return 0
		HandEvaluator.Hand.PAIR:
			return 5
		HandEvaluator.Hand.TWO_PAIR:
			return 15
		HandEvaluator.Hand.THREE_OF_A_KIND:
			return 30
		HandEvaluator.Hand.STRAIGHT:
			return 50
		HandEvaluator.Hand.FLUSH:
			return 70
		HandEvaluator.Hand.FULL_HOUSE:
			return 100
		HandEvaluator.Hand.FOUR_OF_A_KIND:
			return 150
		HandEvaluator.Hand.STRAIGHT_FLUSH:
			return 250
		HandEvaluator.Hand.ROYAL_FLUSH:
			return 500
	return 0
