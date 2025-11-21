extends NPC
class_name NPC_Raffy

enum State {
	FIRST_MEETING,
	AFTER_QUEST
}

var state: int = State.FIRST_MEETING

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	npc_name = "Raffy"

	# Start his idle animation
	if anim != null:
		anim.play("idle_down")  # make sure there is an "idle" animation in SpriteFrames

	# Decide initial state from quests, but default to FIRST_MEETING.
	if QuestManager.is_completed(QuestManager.QuestId.SPAR_RAFFY):
		state = State.AFTER_QUEST
	else:
		state = State.FIRST_MEETING

	_load_state_dialogue()


func _load_state_dialogue() -> void:
	resume_line_index = 0

	if state == State.FIRST_MEETING:
		dialogue = [
			"HEEEY MISTERRRR!",
			"I HAVE A SWORD TOOO!",
			"Oh sorry didn't mean to spook you.",
			"I was just looking for someone to spar with me.",
			"All these other guys around the island are pretty weak though...",
			"If you go beat them up we can spar!"
		]
		choices = []

	elif state == State.AFTER_QUEST:
		dialogue = [
			"Hurry up Mister I'm getting bored.",
			"You can find them all around the island!"
		]
		choices = []

	else:
		dialogue = []
		choices = []


func on_dialogue_finished() -> void:
	if state == State.FIRST_MEETING:
		# Start the next quest for Liston.
		QuestManager.start_quest(QuestManager.QuestId.SPAR_RAFFY)

		# Switch to his post-quest dialogue for future talks.
		state = State.AFTER_QUEST
		_load_state_dialogue()
	# AFTER_QUEST: nothing special on finish for now.
