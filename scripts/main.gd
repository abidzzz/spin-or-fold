extends Control

const SlotMachineScene = preload("res://scenes/slot_machine.tscn")
const HUDScene = preload("res://scenes/HUD.tscn")
const MenuScene = preload("res://scenes/Menu.tscn")

@onready var camera = $Camera2D

var machine
var hud
var menu
var spinning: bool = false
var can_skip_upgrade: bool = false
var background_material: ShaderMaterial
var current_round: int = 1
var game_started: bool = false

func _ready() -> void:
	_setup_balatro_background()
	_show_menu()

func _setup_balatro_background() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = viewport_size
	bg.position = Vector2.ZERO
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	move_child(bg, 0)
	
	var shader = load("res://shaders/background.gdshader")
	if shader:
		background_material = ShaderMaterial.new()
		background_material.shader = shader
		background_material.set_shader_parameter("round_number", 1)
		background_material.set_shader_parameter("time_scale", 0.6)
		bg.material = background_material
	else:
		bg.color = Color(0.05, 0.04, 0.08)

func _show_menu() -> void:
	menu = MenuScene.instantiate()
	menu.modulate.a = 0.0
	add_child(menu)
	
	var tween = create_tween()
	tween.tween_property(menu, "modulate:a", 1.0, 0.8)
	
	menu.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	game_started = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(_start_game)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)

func _start_game() -> void:
	machine = SlotMachineScene.instantiate()
	add_child(machine)
	
	var viewport_size = get_viewport().get_visible_rect().size
	var machine_width = 5 * 158
	machine.position = Vector2(
		(viewport_size.x - machine_width) / 2,
		180
	)
	
	machine.all_reels_stopped.connect(_on_spin_done)
	machine.round_manager.round_cleared.connect(_on_round_cleared)
	machine.round_manager.round_failed.connect(_on_round_failed)
	machine.round_manager.game_won.connect(_on_game_won)
	machine.round_manager.game_over.connect(_on_game_over)
	machine.round_cleared_with_offers.connect(_on_round_cleared_with_offers)
	
	hud = HUDScene.instantiate()
	add_child(hud)
	hud.bet_placed.connect(_on_bet_placed)
	hud.upgrade_chosen.connect(_on_upgrade_chosen)

	_refresh_hud()
	hud.set_round_status("Place your bet!", Color.YELLOW)
	spinning = false

func _input(event) -> void:
	if not game_started:
		return
	
	if hud == null:
		return
	
	if hud.upgrade_screen and hud.upgrade_screen.visible:
		if event.is_action_pressed("ui_cancel") and can_skip_upgrade:
			_skip_upgrade()
		return
	
	if hud.transition_overlay and hud.transition_overlay.visible:
		return
	
	if hud.boss_overlay and hud.boss_overlay.visible:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if spinning:
			var has_spinning_reels = false
			for reel in machine.reels:
				if reel.state != reel.State.STOPPED and reel.state != reel.State.LOCKED:
					has_spinning_reels = true
					break
			if has_spinning_reels:
				machine.stop_next()
				if hud:
					hud.set_round_status("Stopping...", Color.ORANGE)
	
	if event.is_action_pressed("ui_spin") or (event is InputEventKey and event.keycode == KEY_S):
		if not spinning and (hud == null or not hud.upgrade_screen.visible):
			_on_bet_placed(hud.current_bet if hud else HandEvaluator.Hand.PAIR)

func _skip_upgrade() -> void:
	if can_skip_upgrade and hud:
		var offers = machine.upgrade_manager.get_offers()
		if offers.size() > 0:
			_on_upgrade_chosen(randi() % offers.size())
		else:
			hud.hide_upgrade_screen()
			if hud:
				hud.set_round_status("No upgrades available. Place your bet.", Color.YELLOW)

func shake(amount: float) -> void:
	camera.shake(amount)

func _on_bet_placed(hand: HandEvaluator.Hand) -> void:
	if not spinning and hud:
		machine.game_state.place_bet(hand)
		spinning = true
		hud.set_round_status("Spinning... Press SPACE to stop", Color.CYAN)
		machine.spin_all()

func _on_spin_done(outcome: Dictionary) -> void:
	spinning = false
	machine._animate_hand_result(outcome.result_hand)
	
	await get_tree().create_timer(0.5).timeout
	
	if hud:
		hud.show_result(outcome)
	_refresh_hud()
	
	if hud:
		var streak = outcome.get("streak", 0)
		var hand_score = outcome.get("hand_score", 0)
		var hand_bonus = outcome.get("hand_bonus", 0)
		
		if outcome.won:
			var bonus_text = ""
			if hand_bonus > 0:
				bonus_text = " (+%d bonus)" % hand_bonus
			var streak_text = " 🔥x%d" % streak if streak > 0 else ""
			hud.set_round_status("Win! +%d%s%s" % [hand_score, bonus_text, streak_text], Color.GREEN)
		else:
			var consolation = " (consolation)" if hand_score > 0 else ""
			hud.set_round_status("Loss! +%d%s" % [hand_score, consolation], Color.RED)
		
		hud.update_streak(streak)

func _on_round_cleared(round_num: int) -> void:
	if hud:
		hud.show_round_transition("🎉 ROUND %d CLEARED!" % round_num, Color.GOLD)
	await get_tree().create_timer(1.0).timeout

func _on_round_cleared_with_offers(offers: Array) -> void:
	machine.round_manager.advance()
	
	if machine.game_state.is_boss_round():
		if hud:
			await hud.show_boss_intro()
			hud.update_round(machine.game_state.round_number, true)
			hud._flash_message("One spin. Everything.", Color.RED)
		machine.game_state.place_bet(HandEvaluator.Hand.PAIR)
		spinning = true
		machine.spin_all()
	else:
		if hud:
			hud.show_upgrade_screen(offers)
			can_skip_upgrade = false
			await get_tree().create_timer(0.5).timeout
			can_skip_upgrade = true
			hud.set_round_status("Choose an upgrade or press ESC to skip", Color.YELLOW)

func _on_upgrade_chosen(index: int) -> void:
	can_skip_upgrade = false
	var offers = machine.upgrade_manager.get_offers()
	machine.upgrade_manager.apply(offers[index], machine.reels)
	machine.round_manager.advance()
	_refresh_hud()
	if hud:
		hud.set_round_status("Upgrade applied! Place your bet.", Color.YELLOW)

func _on_round_failed() -> void:
	if hud:
		hud.show_round_transition("❌ ROUND FAILED!", Color.RED)
	await get_tree().create_timer(3.0).timeout
	
	machine.game_state.reset_for_new_run()
	machine.reset_reels_for_round()
	
	if hud:
		hud.set_round_status("🔄 New Run! Round 1", Color.YELLOW)
	_refresh_hud()
	
	if hud:
		var stats = machine.game_state.get_run_stats()
		hud._flash_message("Run %d | Best: %d" % [stats.total_runs, stats.best_run], Color.GOLD)

func _on_game_won() -> void:
	machine.game_state.total_wins += 1
	if machine.game_state.round_number > machine.game_state.best_run:
		machine.game_state.best_run = machine.game_state.round_number
	
	if hud:
		hud.show_round_transition("🏆 YOU ESCAPED THE CASINO!", Color.GOLD)
		await get_tree().create_timer(0.5).timeout
		hud.set_round_status("🏆 YOU ESCAPED THE CASINO!", Color.GOLD)
		
		var stats = machine.game_state.get_run_stats()
		hud._flash_message("🏆 Run %d Complete! Best: %d" % [stats.total_runs, stats.best_run], Color.GOLD)
	
	await get_tree().create_timer(3.0).timeout
	_return_to_menu()

func _on_game_over() -> void:
	if hud:
		hud.show_round_transition("💀 THE HOUSE WINS", Color.RED)
		await get_tree().create_timer(0.5).timeout
		hud.set_round_status("💀 THE HOUSE WINS", Color.RED)
	
	await get_tree().create_timer(2.0).timeout
	_return_to_menu()

func _return_to_menu() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	
	await tween.finished
	
	if machine:
		machine.queue_free()
		machine = null
	if hud:
		hud.queue_free()
		hud = null
	
	game_started = false
	spinning = false
	
	_show_menu()
	
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func _refresh_hud() -> void:
	if not hud or not machine:
		return
	var gs = machine.game_state
	hud.update_gold(gs.gold)
	hud.update_round(gs.round_number, gs.is_boss_round())
	hud.update_hands(gs.hands_left)
	hud.update_progress(gs.score, gs.target_score)
	_update_background_round(gs.round_number)
	if hud.has_method("update_round_styling"):
		hud.update_round_styling(gs.round_number)

func _update_background_round(round_num: int) -> void:
	current_round = round_num
	if background_material:
		var tween = create_tween()
		tween.tween_property(background_material, "shader_parameter/transition", 0.0, 0.3)
		tween.tween_callback(func(): 
			background_material.set_shader_parameter("round_number", round_num)
		)
		tween.tween_property(background_material, "shader_parameter/transition", 1.0, 0.3)
