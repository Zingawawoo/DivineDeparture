extends CharacterBody2D
class_name NPC

@export var npc_name: String = "NPC"
@export var dialogue: Array[String] = []
@export var choices: Array[String] = []
@export var repeat_after_finish: bool = true

var resume_line_index: int = 0
var dialogue_finished: bool = false

@onready var interact_area: Area2D = $InteractArea


func can_start_dialogue() -> bool:
	if dialogue_finished and not repeat_after_finish:
		return false

	if DialogueManager.is_dialogue_open():
		return false

	return true


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if can_start_dialogue():
			var bodies := interact_area.get_overlapping_bodies()
			for b in bodies:
				if b.is_in_group("player"):
					DialogueManager.start_dialogue(self)
					return


func on_choice_selected(choice_index: int) -> void:
	# override in subclasses
	pass

func on_dialogue_finished() -> void:
	# override in subclasses
	pass

func on_dialogue_cancelled() -> void:
	# override if needed
	pass
