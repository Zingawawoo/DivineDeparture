extends Node

const SAVE_PATH: String = "user://savegame.json"
const DEFAULT_START_AREA: String = "res://levels/Intro_House.tscn"

# --------- Save / Progress State ---------
var current_checkpoint_id: String = ""
var player_max_hp: int = 5
var player_hp: int = 5
var currency: int = 0
var unlocked_dash: bool = true
var unlocked_block: bool = true
var unlocked_sword: bool = true

# Whether the player (and enemies) are allowed to fight
var combat_enabled: bool = false

# Story flags 
var forest_cleared: bool = false
var mountain_cleared: bool = false
var rival_defeated: bool = false

# Last area and position (for respawns / loads)
var last_area_path: String = ""
var last_player_position: Vector2 = Vector2.ZERO

# ------------ Battle handover (not saved) ------------
var battle_return_area_path: String = ""
var battle_return_position: Vector2 = Vector2.ZERO
var pending_battle_enemy_scene: PackedScene = null
var in_battle: bool = false

# Which quest to complete / start when the current battle ends
var pending_battle_quest_to_complete: int = -1
var pending_battle_quest_to_start: int = -1

func _ready() -> void:
	set_process(false)


func add_currency(amount: int) -> void:
	currency = currency + amount
	if currency < 0:
		currency = 0

	if HUD != null:
		HUD.set_currency(currency)

func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled

# --- NEW: reset everything for a fresh game ---
func reset_to_new_game() -> void:
	current_checkpoint_id = ""
	player_max_hp = 5
	player_hp = 5
	currency = 0

	unlocked_dash = true
	unlocked_block = true
	unlocked_sword = true

	forest_cleared = false
	mountain_cleared = false
	rival_defeated = false

	last_area_path = DEFAULT_START_AREA
	last_player_position = Vector2.ZERO
	
	combat_enabled = false

	# Clear any leftover battle state
	battle_return_area_path = ""
	battle_return_position = Vector2.ZERO
	pending_battle_enemy_scene = null
	in_battle = false

# --- convenience wrappers using SAVE_PATH ---
func save() -> bool:
	return save_to_file(SAVE_PATH)

func load() -> bool:
	return load_from_file(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_to_file(path: String) -> bool:
	var data: Dictionary = {
		"checkpoint": current_checkpoint_id,
		"hp": player_hp,
		"max_hp": player_max_hp,
		"currency": currency,
		"flags": {
			"forest_cleared": forest_cleared,
			"mountain_cleared": mountain_cleared,
			"rival_defeated": rival_defeated
		},
		"last_area": last_area_path,
		"last_pos": [last_player_position.x, last_player_position.y]
	}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true
	
	
func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var result : Dictionary = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = result
	current_checkpoint_id = str(data.get("checkpoint", ""))
	player_hp = int(data.get("hp", 6))
	player_max_hp = int(data.get("max_hp", 6))
	currency = int(data.get("currency", 0))
	var flags: Dictionary = data.get("flags", {})
	forest_cleared = bool(flags.get("forest_cleared", false))
	mountain_cleared = bool(flags.get("mountain_cleared", false))
	rival_defeated = bool(flags.get("rival_defeated", false))
	last_area_path = str(data.get("last_area", "res://levels/Village.tscn"))
	var pos_array: Array = data.get("last_pos", [0, 0])
	if pos_array.size() == 2:
		last_player_position = Vector2(float(pos_array[0]), float(pos_array[1]))
	else:
		last_player_position = Vector2.ZERO
	return true
