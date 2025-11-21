extends NPC
class_name NPC_Dad

# Tutorial states
enum State {
	PRE_TUTORIAL,        # story + choices about Liston
	POST_CHOICE_A,       # "Yes Father."
	POST_CHOICE_B,       # "I only need the blade."
	INTERACT_INTRO,      # explain interact (no wait state anymore)
	ATTACK_INTRO,        # explain attack
	WAIT_ATTACK,         # waiting for attack
	DASH_INTRO,          # explain dash
	WAIT_DASH,           # waiting for dash
	BLOCK_INTRO,         # explain block
	WAIT_BLOCK,          # waiting for block
	PARRY_INTRO,         # explain parry
	WAIT_PARRY,          # waiting for parry
	POST_TRAINING_FINAL  # final lines → quest + teleport
}

const VILLAGE_SCENE_PATH: String = "res://levels/Village.tscn"

var state: int = State.PRE_TUTORIAL


func _ready() -> void:
	npc_name = "Dad"
	_load_state_dialogue()

	# Listen for player combat events
	GameEvents.player_attack_finished.connect(_on_player_attack_finished)
	GameEvents.player_dash_finished.connect(_on_player_dash_finished)
	GameEvents.player_block_finished.connect(_on_player_block_finished)
	GameEvents.player_parry_finished.connect(_on_player_parry_finished)

	# Start the first conversation automatically
	call_deferred("_auto_start")


# ---------------------------------------------------------
#  Dialogue content for each state
# ---------------------------------------------------------
func _load_state_dialogue() -> void:
	resume_line_index = 0

	if state == State.PRE_TUTORIAL:
		dialogue = [
			"Okay Endo, once more.",
			"Patience and timing is key.",
			"Do not rush things.",
			"Anyway that's enough.",
			"You have to go talk to Liston.",
			"What's with that look, you need to make yourself useful.",
			"Just talk to the man. I already owe him much, I can't keep calling in favors for you, boy!"
		]
		choices = [
			"Yes Father.",
			"I only need the blade."
		]

	elif state == State.POST_CHOICE_A:
		dialogue = [
			"First time you have ever spoken with some sense.",
			"Okay then, I will teach you again how to fight."
		]
		choices = []

	elif state == State.POST_CHOICE_B:
		dialogue = [
			"Stubborn kid. My master is rolling in his grave watching you train.",
			"Okay then, I will teach you again how to fight."
		]
		choices = []

	elif state == State.INTERACT_INTRO:
		dialogue = [
			"Before you swing a sword, you need to know how to talk.",
			"When you want to speak to someone, get close and press E or X. Then press Esc or B to leave"
		]
		choices = []

	elif state == State.ATTACK_INTRO:
		dialogue = [
			"Now, your hit.",
			"Face me and attack with J or Left Mouse Button or R2."
		]
		choices = []

	elif state == State.DASH_INTRO:
		dialogue = [
			"Again. This time, move your feet.",
			"Dash with L or Shift or A to close the distance quickly."
		]
		choices = []

	elif state == State.BLOCK_INTRO:
		dialogue = [
			"You will not always be the one swinging.",
			"Hold K or Right Mouse Button or L2 to block and stay standing."
		]
		choices = []

	elif state == State.PARRY_INTRO:
		dialogue = [
			"Blocking is safe, but parrying wins fights.",
			"Raise your guard right as the hit lands to turn their strength against them."
		]
		choices = []

	elif state == State.POST_TRAINING_FINAL:
		dialogue = [
			"Hmm, you are a bit stronger now...",
			"Do not forget to go to Liston's farm."
		]
		choices = []

	else:
		dialogue = []
		choices = []


# ---------------------------------------------------------
#  Start + gating
# ---------------------------------------------------------
func _auto_start() -> void:
	if not DialogueManager.is_dialogue_open():
		DialogueManager.start_dialogue(self)


func can_start_dialogue() -> bool:
	# While waiting for combat inputs, do not reopen dialogue manually
	if state == State.WAIT_ATTACK:
		return false
	if state == State.WAIT_DASH:
		return false
	if state == State.WAIT_BLOCK:
		return false
	if state == State.WAIT_PARRY:
		return false

	return super.can_start_dialogue()


# ---------------------------------------------------------
#  Choices and end-of-dialogue transitions
# ---------------------------------------------------------
func on_choice_selected(choice_index: int) -> void:
	if state == State.PRE_TUTORIAL:
		if choice_index == 0:
			state = State.POST_CHOICE_A
		else:
			state = State.POST_CHOICE_B

		_load_state_dialogue()
		DialogueManager.start_dialogue(self)


func on_dialogue_finished() -> void:
	match state:
		State.PRE_TUTORIAL:
			# Choices handled in on_choice_selected
			pass

		State.POST_CHOICE_A, State.POST_CHOICE_B:
			# Move into interact tutorial explanation
			state = State.INTERACT_INTRO
			_load_state_dialogue()
			# IMPORTANT: defer starting the next dialogue
			DialogueManager.call_deferred("start_dialogue", self)

		State.INTERACT_INTRO:
			# Go straight into attack tutorial
			state = State.ATTACK_INTRO
			_load_state_dialogue()
			DialogueManager.call_deferred("start_dialogue", self)

		State.ATTACK_INTRO:
			HUD.show_prompt("Press J or Left Mouse Button to attack.")
			state = State.WAIT_ATTACK

		State.DASH_INTRO:
			HUD.show_prompt("Press L or Shift to dash.")
			state = State.WAIT_DASH

		State.BLOCK_INTRO:
			HUD.show_prompt("Hold K or Right Mouse Button to block.")
			state = State.WAIT_BLOCK

		State.PARRY_INTRO:
			HUD.show_prompt("Block at the right moment to parry.")
			state = State.WAIT_PARRY

		State.POST_TRAINING_FINAL:
			dialogue_finished = true
			DialogueManager.fade_then(0.4, func() -> void:
				QuestManager.start_quest(QuestManager.QuestId.TUTORIAL_TALK_TO_LINTON)
				_teleport_player_to_village()
			)

		_:
			pass



# ---------------------------------------------------------
#  Reactions to player actions
# ---------------------------------------------------------
func _on_player_attack_finished() -> void:
	if state != State.WAIT_ATTACK:
		return

	HUD.hide_prompt()
	state = State.DASH_INTRO
	_load_state_dialogue()
	DialogueManager.start_dialogue(self)


func _on_player_dash_finished() -> void:
	if state != State.WAIT_DASH:
		return

	HUD.hide_prompt()
	state = State.BLOCK_INTRO
	_load_state_dialogue()
	DialogueManager.start_dialogue(self)


func _on_player_block_finished() -> void:
	if state != State.WAIT_BLOCK:
		return

	HUD.hide_prompt()
	state = State.PARRY_INTRO
	_load_state_dialogue()
	DialogueManager.start_dialogue(self)


func _on_player_parry_finished() -> void:
	if state != State.WAIT_PARRY:
		return

	HUD.hide_prompt()
	state = State.POST_TRAINING_FINAL
	_load_state_dialogue()
	DialogueManager.start_dialogue(self)


# ---------------------------------------------------------
#  Teleport to Village
# ---------------------------------------------------------
func _teleport_player_to_village() -> void:
	var main_node: Main = get_tree().get_first_node_in_group("main") as Main
	if main_node == null:
		push_error("NPC_Dad: Could not find Main node in group 'main'.")
		return

	GameManager.last_area_path = VILLAGE_SCENE_PATH
	GameManager.last_player_position = Vector2.ZERO

	main_node.load_area_external(VILLAGE_SCENE_PATH)
