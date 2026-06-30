extends Node2D

const CardScene = preload("res://scenes/Card.tscn")
const CARD_HEIGHT = 198.0
const NUM_VISIBLE = 10
const SPIN_SPEED = 900.0
const SLOW_SPEED = 180.0

enum State { IDLE, RAMPING, SPINNING, STOPPING, SNAPPING, STOPPED, LOCKED }
var state = State.IDLE

var speed = 0.0
var offset = 0.0
var reel_cards = []
var card_nodes = []

signal reel_stopped(rank: int, suit: String)

@onready var strip = $ClipRect/Strip
@onready var clip_rect = $ClipRect

# Upgrade flags
var is_locked: bool = false
var is_slowed: bool = false
var is_wild: bool = false
var is_doubled: bool = false
var suit_bias: String = ""
var locked_card: Dictionary = {}
var has_locked_card: bool = false
var has_emitted_lock_signal: bool = false

const WILD_CHANCE = 0.25

func setup(cards: Array) -> void:
	reel_cards = cards.duplicate()
	reel_cards.shuffle()
	_build_strip()
	has_locked_card = false
	locked_card = {}
	has_emitted_lock_signal = false
	state = State.IDLE

func _build_strip() -> void:
	for c in card_nodes:
		c.queue_free()
	card_nodes.clear()

	var total = NUM_VISIBLE + 2
	for i in range(total):
		var card = CardScene.instantiate()
		strip.add_child(card)
		card_nodes.append(card)
		var data = reel_cards[i % reel_cards.size()]
		card.setup(data.rank, data.suit)
		card.position = Vector2(0, (i - 1) * CARD_HEIGHT)

	offset = 0.0

func _get_spin_speed() -> float:
	return 500.0 if is_slowed else SPIN_SPEED

func start_spin() -> void:
	if reel_cards.is_empty():
		return
	
	print("start_spin called - is_locked:", is_locked, " has_locked_card:", has_locked_card, " state:", state)
	
	if is_locked and has_locked_card and not locked_card.is_empty():
		print("  → Showing locked card")
		_show_locked_card()
		state = State.LOCKED
		if not has_emitted_lock_signal:
			has_emitted_lock_signal = true
			await get_tree().create_timer(0.01).timeout
			emit_signal("reel_stopped", locked_card.rank, locked_card.suit)
		return
	
	has_emitted_lock_signal = false
	speed = 0.0
	state = State.RAMPING

func _show_locked_card() -> void:
	# Show the locked card centered
	for i in range(card_nodes.size()):
		var card = card_nodes[i]
		card.setup(locked_card.rank, locked_card.suit)
		card.position.y = 0
	
	offset = 0
	_apply_offset()

func begin_stop() -> void:
	if state == State.LOCKED:
		return
	if state == State.SPINNING:
		state = State.STOPPING

func _process(delta):
	match state:
		State.RAMPING:
			speed = move_toward(speed, _get_spin_speed(), _get_spin_speed() * 3.0 * delta)
			if speed >= _get_spin_speed() * 0.98:
				speed = _get_spin_speed()
				state = State.SPINNING
			_scroll(delta)

		State.SPINNING:
			_scroll(delta)

		State.STOPPING:
			speed = move_toward(speed, SLOW_SPEED, SPIN_SPEED * 1.5 * delta)
			_scroll(delta)
			if speed <= SLOW_SPEED + 1.0:
				state = State.SNAPPING

		State.SNAPPING:
			var snap_target = round(offset / CARD_HEIGHT) * CARD_HEIGHT
			offset = lerp(offset, snap_target, 18.0 * delta)
			_apply_offset()
			_recycle_cards()
			if abs(offset - snap_target) < 0.5:
				offset = snap_target
				_apply_offset()
				state = State.STOPPED
				_on_stopped()
		
		State.LOCKED:
			pass

func _get_result_card() -> Node:
	var closest = card_nodes[0]
	for card in card_nodes:
		if abs(card.position.y) < abs(closest.position.y):
			closest = card
	return closest

func _scroll(delta: float) -> void:
	offset += speed * delta
	_apply_offset()
	_recycle_cards()

func _apply_offset() -> void:
	var total_height = CARD_HEIGHT * card_nodes.size()
	for i in range(card_nodes.size()):
		var y = fmod((i * CARD_HEIGHT) + offset, total_height)
		if y > total_height - CARD_HEIGHT:
			y -= total_height
		card_nodes[i].position.y = y - CARD_HEIGHT

func _recycle_cards() -> void:
	for i in range(card_nodes.size()):
		var card = card_nodes[i]
		if card.position.y < -CARD_HEIGHT * 1.5:
			var data = _pick_card()
			card.setup(data.rank, data.suit)

func _pick_card() -> Dictionary:
	if is_wild and randf() < WILD_CHANCE:
		return {"rank": 0, "suit": "w"}

	if suit_bias != "":
		var biased = reel_cards.filter(func(c): return c.suit == suit_bias)
		if randf() < 0.6 and not biased.is_empty():
			return biased[randi() % biased.size()]

	return reel_cards[randi() % reel_cards.size()]

func _on_stopped() -> void:
	_play_bump()
	var closest = _get_result_card()
	
	# Store the card if this reel is locked and we don't have one yet
	if is_locked and not has_locked_card and closest:
		locked_card = {"rank": closest.rank, "suit": closest.suit}
		has_locked_card = true
		print("Reel LOCKED: ", locked_card.rank, " of ", locked_card.suit)
	
	emit_signal("reel_stopped", closest.rank, closest.suit)

func _play_bump() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.05), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func lift_result_card(offset_y: float = -50) -> void:
	var card = _get_result_card()
	if not card:
		return
	
	var original_y = card.position.y
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position:y", original_y + offset_y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate", Color(1.5, 1.5, 0.5), 0.15)
	
	await get_tree().create_timer(1.0).timeout
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(card, "position:y", original_y, 0.3).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)
	return_tween.tween_property(card, "modulate", Color.WHITE, 0.3)

func reset_lock() -> void:
	if is_locked:
		has_locked_card = false
		locked_card = {}
		has_emitted_lock_signal = false
		state = State.IDLE
		print("Lock reset for reel")

func zoom_out_result_card(scale_amount: float = 0.7) -> void:
	var card = _get_result_card()
	if not card:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(scale_amount, scale_amount), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate", Color(0.6, 0.6, 0.8), 0.15)
	
	await get_tree().create_timer(0.8).timeout
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(card, "modulate", Color.WHITE, 0.3)
