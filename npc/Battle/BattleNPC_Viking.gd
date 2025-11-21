extends NPC
class_name BattleNPC_Viking

# This NPC will send you into a battle scene once,
# but only while HELP_LISTON_ON_FARM is active.

enum State {
	LOCKED,        # quest not active yet
	READY,         # quest active, battle not done
	AFTER_BATTLE   # quest completed
}

@export var battle_scene_path: String = "res://levels/Farm_Arena.tscn"
@export var battle_enemy_scene: PackedScene    # <-- opponent to spawn in battle

@export var quest_to_complete: int = QuestManager.QuestId.HELP_LISTON_ON_FARM
@export var quest_to_start_next: int = -1    # -1 means "no follow-up quest"

var state: int = State.LOCKED

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	npc_name = "Aditya"

	# We usually do NOT want this guy to repeat his "ready" line forever
	# after the fight is done.
	repeat_after_finish = true    # can keep talking AFTER_BATTLE if you want

	if anim != null:
		anim.play("idle")  # make sure you have an "idle" animation

	_update_state_from_quests()
	_load_state_dialogue()


func _update_state_from_quests() -> void:
	# Quest flow we decided earlier:
	#  - HELP_LISTON_ON_FARM is started by Liston.
	#  - The battle happens while this quest is active.
	#  - After the battle, you will complete that quest (from the battle scene).

	if QuestManager.is_completed(QuestManager.QuestId.HELP_LISTON_ON_FARM):
		state = State.AFTER_BATTLE
	elif QuestManager.is_active(QuestManager.QuestId.HELP_LISTON_ON_FARM):
		state = State.READY
	else:
		state = State.LOCKED


func _load_state_dialogue() -> void:
	resume_line_index = 0

	if state == State.LOCKED:
		dialogue = [
			"I don't have time for weaklings.",
			"This shitty farm has nothing."
		]
		choices = []

	elif state == State.READY:
		dialogue = [
			"So Liston sent you.",
			"Snotty brat, let's see if you know how to fight."
		]
		choices = []

	elif state == State.AFTER_BATTLE:
		dialogue = [
			"Fine I'll leave",
			"Endo, I'll remember that name..."
		]
		choices = []

	else:
		dialogue = []
		choices = []


func can_start_dialogue() -> bool:
	# Every time the player presses interact, refresh the quest-based state.
	_update_state_from_quests()
	_load_state_dialogue()

	# Then defer to the base NPC logic
	var allowed: bool = super.can_start_dialogue()
	return allowed
	

func on_dialogue_finished() -> void:
	if state == State.READY:
		# 1) Remember where to return AFTER battle
		var player: Player = get_tree().get_first_node_in_group("player") as Player
		if player != null:
			GameManager.battle_return_area_path = GameManager.last_area_path
			GameManager.battle_return_position = player.global_position

		# 2) Set battle map as the "current area" for Main
		GameManager.last_area_path = battle_scene_path
		GameManager.last_player_position = Vector2.ZERO

		# 3) Tell the battle scene which enemy to spawn
		GameManager.pending_battle_enemy_scene = battle_enemy_scene

		# 4) Tell the battle which quest to complete / start when it ends
		GameManager.pending_battle_quest_to_complete = quest_to_complete
		GameManager.pending_battle_quest_to_start = quest_to_start_next

		# 5) Mark that we are now in a battle context
		GameManager.in_battle = true

		# 6) Fade to Main, which will then load the battle map
		DialogueManager.fade_then(0.4, func() -> void:
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		)
