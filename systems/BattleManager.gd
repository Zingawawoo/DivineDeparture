extends Node
class_name BattleManager

func _ready() -> void:
	# In battle: allow combat
	GameManager.set_combat_enabled(true)


func _end_battle_and_return() -> void:
	GameManager.set_combat_enabled(false)
	await TransitionManager.change_scene_to_file_with_fade("res://Main.tscn")
