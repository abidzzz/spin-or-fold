class_name Upgrade

enum Type {
	WEIGHT,   # one reel favors a specific suit
	LOCK,     # one reel keeps its card from last spin
	SLOW,     # one reel spins slower — easier to stop precisely
	WILD,     # one reel occasionally shows a wild card
	DOUBLE,   # one reel's card counts twice in hand evaluation
}

const DESCRIPTIONS = {
	Type.WEIGHT: "One reel favors a chosen suit",
	Type.LOCK:   "One reel holds its card between spins",
	Type.SLOW:   "One reel spins slower — easier to time",
	Type.WILD:   "One reel randomly shows a Wild card",
	Type.DOUBLE: "One reel's card counts twice in your hand",
}

var type: Type
var target_reel: int       # which reel (0-4) this applies to
var suit_bias: String = "" # for WEIGHT upgrade

func _init(t: Type, reel_idx: int, bias: String = "") -> void:
	type = t
	target_reel = reel_idx
	suit_bias = bias

func get_description() -> String:
	return DESCRIPTIONS[type]
