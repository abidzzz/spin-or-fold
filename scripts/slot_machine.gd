extends Node2D

const ReelScene = preload("res://scenes/Reel.tscn")
const RoundManagerScene = preload("res://scenes/round_manager.tscn")
var round_manager: Node

const REEL_COUNT = 5
const REEL_SPACING = 158      # 138px card + 20px gap
const STAGGER_DELAY = 0.12    # seconds between each reel starting

var reels: Array = []
var stopped_count = 0
var results: Array = []       # [{rank, suit}, ...] one per reel

signal all_reels_stopped(results: Array)
signal round_cleared_with_offers(offers: Array)

@onready var reels_node = $Reels
var game_state: GameState = GameState.new()
var upgrade_manager: UpgradeManager = UpgradeManager.new()
var doubled_reel: int = -1

# Full deck — 52 cards
var deck: Array = []

func _ready():
	_build_deck()
	_spawn_reels()
	round_manager = RoundManagerScene.instantiate()
	add_child(round_manager)
	round_manager.setup(game_state)
	round_manager.round_cleared.connect(_on_round_cleared)
	round_manager.round_failed.connect(_on_round_failed)
	round_manager.game_won.connect(_on_game_won)
	round_manager.game_over.connect(_on_game_over)

func _build_deck() -> void:
	var suits = ["c", "d", "h", "s"]
	var ranks = [1,2,3,4,5,6,7,8,9,10,11,12,13]
	for s in suits:
		for r in ranks:
			deck.append({"rank": r, "suit": s})

func _spawn_reels() -> void:
	for i in range(REEL_COUNT):
		var reel = ReelScene.instantiate()
		reels_node.add_child(reel)
		reel.position = Vector2(i * REEL_SPACING, 0)
		reel.setup(deck)
		reel.reel_stopped.connect(_on_reel_stopped)
		reels.append(reel)

func spin_all() -> void:
	stopped_count = 0
	results.clear()
	results.resize(REEL_COUNT)
	for i in range(REEL_COUNT):
		# Stagger each reel start
		await get_tree().create_timer(STAGGER_DELAY).timeout
		reels[i].start_spin()

func stop_next() -> void:
	for reel in reels:
		# Skip locked reels
		if reel.state == reel.State.LOCKED:
			continue
		if reel.state == reel.State.SPINNING or reel.state == reel.State.RAMPING:
			reel.begin_stop()
			return

func reset_reels_for_round() -> void:
	for reel in reels:
		# Reset lock states
		if reel.is_locked:
			reel.has_locked_card = false
			reel.locked_card = {}
			reel.has_emitted_lock_signal = false
			reel.state = reel.State.IDLE
		# Rebuild the strip with fresh cards
		reel._build_strip()
		reel.state = reel.State.IDLE

func _on_reel_stopped(rank: int, suit: String) -> void:
	if stopped_count >= REEL_COUNT:
		return
	
	get_parent().shake(3.0)
	results[stopped_count] = {"rank": rank, "suit": suit}
	stopped_count += 1
	
	if stopped_count == REEL_COUNT:
		doubled_reel = -1
		for i in range(reels.size()):
			if reels[i].is_doubled:
				doubled_reel = i
				break
		var hand = HandEvaluator.evaluate(results, doubled_reel)
		_flash_result_cards(true)
		var outcome: Dictionary
		if game_state.is_boss_round():
			outcome = game_state.resolve_boss_spin(hand)
		else:
			outcome = game_state.resolve_spin(hand)
		round_manager.check_after_spin()
		emit_signal("all_reels_stopped", outcome)
func _get_reel_index_by_result(rank, suit) -> int:
	for i in range(reels.size()):
		if reels[i].state == reels[i].State.STOPPED:
			return i
	return -1

func flash_win() -> void:
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property($Sprite2D, "modulate", Color(1.5, 1.5, 0.2), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)

func flash_lose() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1.2, 0.2, 0.2), 0.15)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.3)

func _flash_result_cards(won: bool) -> void:
	for reel in reels:
		var card = reel._get_result_card()
		if card:
			if won:
				card.flash_win()
			else:
				card.flash_lose()

func _on_round_cleared(round_num: int) -> void:
	print("=== ROUND %d CLEARED ===" % round_num)
	var offers = upgrade_manager.get_offers()
	emit_signal("round_cleared_with_offers", offers)

func _on_round_failed() -> void:
	print("=== ROUND FAILED — try again ===")
	game_state.hands_left = 5
	game_state.score = 0

func _on_game_won() -> void:
	print("=== YOU ESCAPED THE CASINO ===")

func _on_game_over() -> void:
	print("=== GAME OVER — THE HOUSE WINS ===")

func _get_matching_cards(hand: HandEvaluator.Hand) -> Array:
	var matching = []
	var ranks = results.map(func(c): return c.rank)
	
	var freq = {}
	for r in ranks:
		freq[r] = freq.get(r, 0) + 1
	
	var target_rank = -1
	for r in freq:
		if freq[r] >= 3:
			target_rank = r
			break
	
	if target_rank == -1:
		return matching
	
	for i in range(results.size()):
		if results[i].rank == target_rank:
			matching.append(i)
	
	return matching

func _animate_hand_result(hand: HandEvaluator.Hand) -> void:
	var hand_name = HandEvaluator.get_hand_name(hand)
	var color = _get_hand_color(hand)
	_show_hand_label(hand_name, color)
	
	var matching_indices = _get_matching_cards_for_hand(hand)
	
	if not matching_indices.is_empty():
		# Zoom out matching cards one by one with delay
		for i in matching_indices:
			var reel = reels[i]
			var delay = i * 0.02
			await get_tree().create_timer(delay).timeout
			reel.zoom_out_result_card(0.67)
		
		if hand >= HandEvaluator.Hand.FULL_HOUSE:
			await get_tree().create_timer(0.5).timeout
			for reel in reels:
				var card = reel._get_result_card()
				if card:
					card.celebrate()
		
		if hand == HandEvaluator.Hand.ROYAL_FLUSH:
			await get_tree().create_timer(0.3).timeout
			for reel in reels:
				var card = reel._get_result_card()
				if card:
					var tween = create_tween()
					tween.tween_property(card, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)

func _get_hand_color(hand: HandEvaluator.Hand) -> Color:
	match hand:
		HandEvaluator.Hand.ROYAL_FLUSH:
			return Color(1, 0.8, 0.2)
		HandEvaluator.Hand.STRAIGHT_FLUSH:
			return Color(0.2, 0.8, 1.0)
		HandEvaluator.Hand.FOUR_OF_A_KIND:
			return Color(1, 0.2, 0.8)
		HandEvaluator.Hand.FULL_HOUSE:
			return Color(0.2, 1, 0.4)
		HandEvaluator.Hand.FLUSH:
			return Color(0.2, 0.4, 1)
		HandEvaluator.Hand.STRAIGHT:
			return Color(1, 0.4, 0.2)
		HandEvaluator.Hand.THREE_OF_A_KIND:
			return Color(1, 0.6, 0.2)
		HandEvaluator.Hand.TWO_PAIR:
			return Color(1, 1, 0)
		HandEvaluator.Hand.PAIR:
			return Color(0.6, 0.6, 1)
		_:
			return Color.WHITE

func _get_matching_cards_for_hand(hand: HandEvaluator.Hand) -> Array:
	var matching = []
	var ranks = results.map(func(c): return c.rank)
	
	var freq = {}
	for r in ranks:
		freq[r] = freq.get(r, 0) + 1
	
	var target_ranks = []
	
	match hand:
		HandEvaluator.Hand.PAIR:
			for r in freq:
				if freq[r] == 2:
					target_ranks.append(r)
					break
		
		HandEvaluator.Hand.TWO_PAIR:
			for r in freq:
				if freq[r] == 2:
					target_ranks.append(r)
			if target_ranks.size() < 2:
				for r in freq:
					if freq[r] >= 2:
						target_ranks.append(r)
						if target_ranks.size() >= 2:
							break
		
		HandEvaluator.Hand.THREE_OF_A_KIND:
			for r in freq:
				if freq[r] >= 3:
					target_ranks.append(r)
					break
		
		HandEvaluator.Hand.FOUR_OF_A_KIND:
			for r in freq:
				if freq[r] >= 4:
					target_ranks.append(r)
					break
		
		HandEvaluator.Hand.FULL_HOUSE:
			for r in freq:
				if freq[r] == 3:
					target_ranks.append(r)
					break
			if target_ranks.is_empty():
				for r in freq:
					if freq[r] >= 2:
						target_ranks.append(r)
						break
		
		_:
			return []
	
	if target_ranks.is_empty():
		return []
	
	for i in range(results.size()):
		if results[i].rank in target_ranks:
			matching.append(i)
	
	return matching

func _show_hand_label(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(400, 100)
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(0.5, 0.5), 0.0)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", Vector2(400, 60), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.5)
	tween.tween_callback(label.queue_free)

func reset_locks_for_round() -> void:
	for reel in reels:
		if reel.is_locked:
			reel.reset_lock()
			
# Add this function to slot_machine.gd
func get_reel_index(reel: Node) -> int:
	for i in range(reels.size()):
		if reels[i] == reel:
			return i
	return -1
