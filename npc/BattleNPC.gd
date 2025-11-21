extends NPC
class_name BattleNPC_Simple

## Battle map to load
@export var battle_scene_path: String = "res://levels/Farm_Arena.tscn"

## Which enemy to spawn inside the battle map
@export var enemy_scene: PackedScene

## Which choice triggers the fight (-1 = ANY ending triggers a fight)
@export var fight_choice_index: int = -1

var _last_choice_index: int = -1


func on_choice_selected(choice_index: int) -> void:
	_last_choice_index = choice_index


func on_dialogue_finished() -> void:
	# If we require a specific choice, check it
	if fight_choice_index >= 0 and _last_choice_index != fight_choice_index:
		_last_choice_index = -1
		return

	_last_choice_index = -1

	if enemy_scene == null:
		push_error("BattleNPC_Simple has no enemy_scene assigned.")
		return

	# Store where the player should return to
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		GameManager.battle_return_area_path = GameManager.last_area_path
		GameManager.battle_return_position = player.global_position

	# Set the battle map to load
	GameManager.last_area_path = battle_scene_path
	GameManager.last_player_position = Vector2.ZERO

	# Push enemy to GameManager so BattleSceneBase knows what to spawn
	GameManager.pending_battle_enemy_scene = enemy_scene

	# Mark that we are in battle context
	GameManager.in_battle = true

	# Fade → go to Main → Main loads battle scene → enemy spawns
	DialogueManager.fade_then(0.4, func() -> void:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
