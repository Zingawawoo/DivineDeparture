extends Node

signal quest_started(id: int)
signal quest_completed(id: int)

enum QuestId {
	NONE = -1,
	TUTORIAL_TALK_TO_LINTON,
	HELP_LISTON_ON_FARM,
	CLEAR_TOURNAMENT_PATH,
	SPAR_RAFFY
}

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}


func start_quest(id: int) -> void:
	# Do not restart a quest that is already completed.
	if completed_quests.get(id, false):
		return

	active_quests[id] = true
	emit_signal("quest_started", id)
	print("Quest started: ", id)


func complete_quest(id: int) -> void:
	if active_quests.has(id):
		active_quests.erase(id)

	completed_quests[id] = true
	print("Quest completed: ", id)


func is_active(id: int) -> bool:
	return active_quests.get(id, false)


func is_completed(id: int) -> bool:
	return completed_quests.get(id, false)
