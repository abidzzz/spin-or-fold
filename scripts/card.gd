extends Node2D
class_name Card

# e.g. rank = 1, suit = "d"  (Ace = 1)
var rank: int
var suit: String

const SUIT_MAP = {"c": "Clubs", "d": "Diamonds", "h": "Hearts", "s": "Spades", "w": "Wild"}
const RANK_NAMES = {
	0:"W",1: "A", 2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9", 
	10: "10", 11: "J", 12: "Q", 13: "K"
}

@onready var sprite = $Sprite2D

func setup(p_rank: int, p_suit: String) -> void:
	rank = p_rank
	suit = p_suit
	_load_texture()
	$Sprite2D.offset = Vector2(0, 0)
	$Sprite2D.centered = false

func _load_texture() -> void:
	var suit_folder = SUIT_MAP[suit]
	var path = "res://assets/cards/%s/%s%s.png" % [suit_folder, rank, suit]
	var tex = load(path)
	if tex:
		sprite.texture = tex
	else:
		push_error("Card texture not found: " + path)

func get_value() -> int:
	# For hand evaluation - Ace = 1
	return rank

# Convert to dictionary format for HandEvaluator
func to_dict() -> Dictionary:
	return {"rank": rank, "suit": suit}

# Get display name (e.g. "Ace of Spades", "10 of Hearts")
func get_display_name() -> String:
	var rank_name = RANK_NAMES.get(rank, str(rank))
	var suit_name = SUIT_MAP.get(suit, suit)
	return rank_name + " of " + suit_name
func flash_win() -> void:
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property($Sprite2D, "modulate", Color(1.5, 1.5, 0.2), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)

func flash_lose() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1.2, 0.2, 0.2), 0.15)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.3)
	
func pop_up(delay: float = 0.0) -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.0)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Glow effect
	var glow = $Sprite2D.duplicate()
	glow.modulate = Color(1, 1, 0, 0.3)
	glow.scale = Vector2(1.2, 1.2)
	add_child(glow)
	var glow_tween = create_tween()
	glow_tween.tween_property(glow, "modulate:a", 0.0, 0.5).set_delay(delay + 0.3)
	glow_tween.tween_callback(glow.queue_free)

func celebrate() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -50), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "modulate", Color(1.5, 1.5, 0.5), 0.3)
	tween.chain().tween_property(self, "position", position, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property($Sprite2D, "modulate", Color.WHITE, 0.5)
