class_name UpgradeManager

var active_upgrades: Array = []

func get_offers() -> Array:
	var pool = []
	var types = Upgrade.Type.values()
	types.shuffle()
	for i in range(min(3, types.size())):
		var reel_idx = randi() % 5
		pool.append(Upgrade.new(types[i], reel_idx))
	return pool

func apply(upgrade: Upgrade, reels: Array) -> void:
	active_upgrades.append(upgrade)
	var reel_index = upgrade.target_reel
	
	if reel_index < 0 or reel_index >= reels.size():
		print("ERROR: Invalid reel index: ", reel_index)
		return
	
	var reel = reels[reel_index]
	
	print("Applying upgrade to reel ", reel_index + 1, " (index ", reel_index, ")")
	
	match upgrade.type:
		Upgrade.Type.WEIGHT: 
			reel.suit_bias = upgrade.suit_bias
			print("  → WEIGHT applied")
		Upgrade.Type.LOCK:   
			reel.is_locked = true
			reel.has_locked_card = false
			reel.locked_card = {}
			reel.has_emitted_lock_signal = false
			reel.state = reel.State.IDLE
			print("  → LOCK applied (will lock on next spin)")
		Upgrade.Type.SLOW:   
			reel.is_slowed = true
			print("  → SLOW applied")
		Upgrade.Type.WILD:   
			reel.is_wild = true
			print("  → WILD applied")
		Upgrade.Type.DOUBLE: 
			reel.is_doubled = true
			print("  → DOUBLE applied")
