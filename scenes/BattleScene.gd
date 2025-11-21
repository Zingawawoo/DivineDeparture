extends Node2D
class_name BattleSceneBase

@export var quest_to_complete: int = QuestManager.QuestId.NONE
@export var quest_to_start_next: int = QuestManager.QuestId.NONE
@export var main_scene_path: String = "res://scenes/Main.tscn"

var _battle_ended: bool = false


func _ready() -> void:
	# Enable combat while in battle
	if GameManager.has_method("set_combat_enabled"):
		GameManager.set_combat_enabled(true)

	add_to_group("battle_scene")

	# --- PULL QUEST INFO FROM GAMEMANAGER (set by BattleNPC) ---
	if GameManager.pending_battle_quest_to_complete != QuestManager.QuestId.NONE:
		quest_to_complete = GameManager.pending_battle_quest_to_complete
		GameManager.pending_battle_quest_to_complete = QuestManager.QuestId.NONE

	if GameManager.pending_battle_quest_to_start != QuestManager.QuestId.NONE:
		quest_to_start_next = GameManager.pending_battle_quest_to_start
		GameManager.pending_battle_quest_to_start = QuestManager.QuestId.NONE

	_spawn_pending_enemy()
	set_process(true)


func _spawn_pending_enemy() -> void:
	var scene: PackedScene = GameManager.pending_battle_enemy_scene
	if scene == null:
		return

	var enemy_instance: Node = scene.instantiate()

	var container: Node = get_node_or_null("World/EnemyContainer")
	if container == null:
		container = get_node_or_null("World")
	if container == null:
		container = self

	container.add_child(enemy_instance)

	var spawn: Node2D = get_node_or_null("World/EnemySpawn") as Node2D
	if spawn != null and enemy_instance is Node2D:
		var enemy_as_node2d: Node2D = enemy_instance as Node2D
		enemy_as_node2d.global_position = spawn.global_position

	GameManager.pending_battle_enemy_scene = null


func _process(_delta: float) -> void:
	if _battle_ended:
		return

	var enemies: Array = get_tree().get_nodes_in_group("battle_enemy")
	if enemies.size() == 0:
		end_battle_player_won()


func end_battle_player_won() -> void:
	if _battle_ended:
		return
	_battle_ended = true

	# 1) Quest updates
	if quest_to_complete != QuestManager.QuestId.NONE:
		if QuestManager.is_active(quest_to_complete):
			QuestManager.complete_quest(quest_to_complete)

	if quest_to_start_next != QuestManager.QuestId.NONE:
		QuestManager.start_quest(quest_to_start_next)

	# 2) Restore overworld area + position
	if GameManager.battle_return_area_path != "":
		GameManager.last_area_path = GameManager.battle_return_area_path
		GameManager.last_player_position = GameManager.battle_return_position

	GameManager.battle_return_area_path = ""
	GameManager.battle_return_position = Vector2.ZERO
	GameManager.in_battle = false

	# 3) Fade and go back through Main
	DialogueManager.fade_then(0.4, func() -> void:
		get_tree().change_scene_to_file(main_scene_path)
	)
