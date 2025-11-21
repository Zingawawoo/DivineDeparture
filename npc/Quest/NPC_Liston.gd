extends NPC
class_name NPC_Liston

enum State {
	FIRST_MEETING,
	AFTER_QUEST
}

var state: int = State.FIRST_MEETING

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	npc_name = "Liston"

	# Start his idle animation
	if anim != null:
		anim.play("idle")  # make sure there is an "idle" animation in SpriteFrames

	# Decide initial state from quests, but default to FIRST_MEETING.
	if QuestManager.is_completed(QuestManager.QuestId.TUTORIAL_TALK_TO_LINTON):
		state = State.AFTER_QUEST
	elif QuestManager.is_active(QuestManager.QuestId.HELP_LISTON_ON_FARM):
		state = State.AFTER_QUEST
	elif QuestManager.is_completed(QuestManager.QuestId.HELP_LISTON_ON_FARM):
		state = State.AFTER_QUEST
	else:
		state = State.FIRST_MEETING

	_load_state_dialogue()


func _load_state_dialogue() -> void:
	resume_line_index = 0

	if state == State.FIRST_MEETING:
		dialogue = [
			"So you're Endo, huh?",
			"I see you got a sword on yeh.",
			"There's been a guy causing touble around the farm mind helpin' me out.",
			"Seeing as your Ocelot's kid, it should be light work for yeh."
		]
		choices = []

	elif state == State.AFTER_QUEST:
		dialogue = [
			"Don't keep me waiting Endo.",
			"He's waiting west from here."
		]
		choices = []

	else:
		dialogue = []
		choices = []


func on_dialogue_finished() -> void:
	if state == State.FIRST_MEETING:
		# If Dad's quest is active, finish it now.
		if QuestManager.is_active(QuestManager.QuestId.TUTORIAL_TALK_TO_LINTON):
			QuestManager.complete_quest(QuestManager.QuestId.TUTORIAL_TALK_TO_LINTON)

		# Start the next quest for Liston.
		QuestManager.start_quest(QuestManager.QuestId.HELP_LISTON_ON_FARM)

		# Switch to his post-quest dialogue for future talks.
		state = State.AFTER_QUEST
		_load_state_dialogue()
	# AFTER_QUEST: nothing special on finish for now.
