extends Node

var dialogue_font: Font = load("res://assets/fonts/game_over.ttf")
var blip_stream: AudioStream = load("res://assets/sfx/SFX_RetroSinglev5.wav")

var ui: Control
var npc_ref: NPC = null

var is_open: bool = false
var fade_in_progress: bool = false
var in_choice_mode: bool = false

# typing
var typing_speed: float = 0.03
var typing_index: int = 0
var typing_timer: float = 0.0
var is_typing: bool = false
var current_text: String = ""
var current_line_index: int = 0

# choices
var choices_nodes: Array = []
var current_choice_index: int = 0

var blip_player: AudioStreamPlayer


func _ready() -> void:
	
	set_process(true)
	ui = HUD.get_node("DialogueBox")
	ui.visible = false

	blip_player = AudioStreamPlayer.new()
	blip_player.stream = blip_stream
	add_child(blip_player)

	var name_label := ui.get_node("PanelRoot/Panel/NameLabel")
	var text_label := ui.get_node("PanelRoot/Panel/TextLabel")

	if dialogue_font:
		name_label.add_theme_font_override("font", dialogue_font)
		text_label.add_theme_font_override("font", dialogue_font)


func is_dialogue_open() -> bool:
	return is_open


# ============================================================
#  FADE API (Option A architecture)
# ============================================================

func fade_then(duration: float, callback: Callable) -> void:
	if fade_in_progress:
		return

	fade_in_progress = true
	_lock_player()

	var t1 : Tween = HUD.fade_to_black(duration)
	await t1.finished

	callback.call()

	var t2 : Tween = HUD.fade_from_black(duration)
	await t2.finished

	fade_in_progress = false
	_unlock_player()


# ============================================================
#  START / END
# ============================================================

func start_dialogue(npc: NPC) -> void:
	if fade_in_progress:
		return

	_lock_player()

	npc_ref = npc
	is_open = true
	in_choice_mode = false
	current_choice_index = 0

	ui.visible = true

	# NEW: set speaker name
	var name_label: Label = ui.get_node("PanelRoot/Panel/NameLabel")
	if npc_ref != null:
		name_label.text = npc_ref.npc_name

	# resume index
	current_line_index = npc.resume_line_index
	if current_line_index < 0:
		current_line_index = 0
	if current_line_index >= npc.dialogue.size():
		current_line_index = npc.dialogue.size() - 1

	_start_typing(npc.dialogue[current_line_index])
	_clear_choice_list()


func _end_dialogue() -> void:
	ui.visible = false
	is_open = false
	is_typing = false
	in_choice_mode = false

	_unlock_player()

	if npc_ref != null:
		npc_ref.resume_line_index = 0
		npc_ref.on_dialogue_finished()

	npc_ref = null


func _cancel_dialogue() -> void:
	if npc_ref != null:
		npc_ref.resume_line_index = current_line_index
		npc_ref.on_dialogue_cancelled()

	ui.visible = false
	is_open = false
	is_typing = false
	in_choice_mode = false

	_unlock_player()
	npc_ref = null


# ============================================================
#  INPUT PROCESS
# ============================================================

func _process(delta: float) -> void:
	if not is_open:
		return
	if npc_ref == null:
		return
	if fade_in_progress:
		return

	# ESC closes
	if Input.is_action_just_pressed("ui_cancel"):
		_cancel_dialogue()
		return

	# typing
	if is_typing:
		_process_typing(delta)
		return

	# choices
	if in_choice_mode:
		_process_choice_input()
		return

	# advance on interact
	if Input.is_action_just_pressed("interact"):
		_advance_dialogue()


# ============================================================
#  TYPING
# ============================================================

func _process_typing(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		var text_label := ui.get_node("PanelRoot/Panel/TextLabel") as Label
		text_label.text = current_text
		is_typing = false
		return

	typing_timer += delta
	if typing_timer >= typing_speed:
		typing_timer -= typing_speed
		typing_index += 1

		var lbl := ui.get_node("PanelRoot/Panel/TextLabel") as Label
		lbl.text = current_text.substr(0, typing_index)
		
		_play_blip()

		if typing_index >= current_text.length():
			is_typing = false


func _start_typing(new_text: String) -> void:
	# Optional per-line "Name: text" override
	var text_only: String = new_text

	var colon_index: int = new_text.find(":")
	if colon_index != -1:
		var possible_name: String = new_text.substr(0, colon_index).strip_edges()
		var remainder: String = new_text.substr(colon_index + 1).strip_edges()

		if possible_name != "":
			var name_label: Label = ui.get_node("PanelRoot/Panel/NameLabel") as Label
			name_label.text = possible_name
			text_only = remainder

	current_text = text_only
	typing_index = 0
	typing_timer = 0.0
	is_typing = true

	var text_label: Label = ui.get_node("PanelRoot/Panel/TextLabel") as Label
	text_label.text = ""

func _play_blip() -> void:
	if blip_player != null and blip_stream != null:
		# Prevent layering too many blips
		if blip_player.playing:
			blip_player.stop()

		blip_player.pitch_scale = randf_range(0.95, 1.05)  # small variation feels better
		blip_player.volume_db = -22.0
		blip_player.play()


# ============================================================
#  ADVANCE
# ============================================================

func _advance_dialogue() -> void:
	current_line_index += 1

	if current_line_index < npc_ref.dialogue.size():
		_start_typing(npc_ref.dialogue[current_line_index])
		return

	# end reached
	if npc_ref.choices.size() > 0:
		_show_choices()
		return

	_end_dialogue()


# ============================================================
#  CHOICES
# ============================================================

func _clear_choice_list() -> void:
	var container := ui.get_node("PanelRoot/Panel/ChoicesContainer") as VBoxContainer
	for child in container.get_children():
		child.queue_free()
	choices_nodes.clear()


func _show_choices() -> void:
	in_choice_mode = true
	current_choice_index = 0
	_clear_choice_list()

	var container := ui.get_node("PanelRoot/Panel/ChoicesContainer") as VBoxContainer

	for i in npc_ref.choices.size():
		var hbox := HBoxContainer.new()
		container.add_child(hbox)

		var arrow := Label.new()
		
		arrow.add_theme_font_override("font", dialogue_font)

		if i == 0:
			arrow.text = "▶"
		else:
			arrow.text = ""

		hbox.add_child(arrow)

		var lbl := Label.new()
		lbl.text = npc_ref.choices[i]
		lbl.add_theme_font_override("font", dialogue_font)
		lbl.add_theme_font_size_override("font_size", 72)
		hbox.add_child(lbl)

		choices_nodes.append(hbox)


func _process_choice_input() -> void:
	if Input.is_action_just_pressed("ui_down"):
		current_choice_index += 1
		if current_choice_index >= npc_ref.choices.size():
			current_choice_index = 0
		_update_choice_arrows()

	if Input.is_action_just_pressed("ui_up"):
		current_choice_index -= 1
		if current_choice_index < 0:
			current_choice_index = npc_ref.choices.size() - 1
		_update_choice_arrows()

	if Input.is_action_just_pressed("interact"):
		var idx := current_choice_index
		var npc := npc_ref         # KEEP REFERENCE BEFORE ENDING

		_end_dialogue()            # This deletes npc_ref inside it!

		if npc != null and npc.has_method("on_choice_selected"):
			npc.on_choice_selected(idx)

func _update_choice_arrows() -> void:
	for i in choices_nodes.size():
		var arrow : Label = choices_nodes[i].get_child(0)
		if i == current_choice_index:
			arrow.text = "▶"
		else:
			arrow.text = ""


# ============================================================
#  PLAYER INPUT LOCKING
# ============================================================

func _lock_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		p.set_input_enabled(false)

func _unlock_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		p.set_input_enabled(true)
