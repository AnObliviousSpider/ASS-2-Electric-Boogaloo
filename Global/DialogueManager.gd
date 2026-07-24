extends Node


signal dialogue_closed
signal level_dialogue_closed

var _dialogue_box_displayed: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_primary"):
		if _dialogue_box_displayed:
			EventBus.dialogue_next.emit()


func open_dialogue() -> void:
	_dialogue_box_displayed = true


func close_dialogue() -> void:
	_dialogue_box_displayed = false
	dialogue_closed.emit()


func open_level_dialogue() -> void:
	_dialogue_box_displayed = true


func close_level_dialogue() -> void:
	_dialogue_box_displayed = false
	dialogue_closed.emit()
	level_dialogue_closed.emit()

var dialogue_levels: Dictionary = {
	1: [
		{"align": "right", "text": "Lets make a deal then… This old machine is still here. You beat me five times. We delay the end one more day."},
		{"align": "left", "text": "And if you win?"},
		{"align": "right", "text": "We play again. Each ball you lose, is another star I pluck from the sky."},
		{"align": "left", "text": "Until there are no more stars?"},
		{"align": "right", "text": "You would still be here. For a few seconds."},
	],
	2: [
		{"align": "left", "text": "There are not that many planets left"},
		{"align": "right", "text": "I could start fishing for more in some black holes? Fun date idea right?"},
		{"align": "left", "text": "Come on, there is got to be some way to keep this going… Right?"},
		{"align": "right", "text": "I could try cutting the planets in two… Wait no then they would not work as balls."},
		{"align": "left", "text": "Well we still have not been kicked out of the arcade yet? One more game?"},
	],
	3: [
		{"align": "left", "text": "uh- so- I wish- You WOULD JUST STOP WITH THIS NONSENSE
"},
		{"align": "right", "text": "You have no idea what you are talking about."},
		{"align": "left", "text": "YOU ALWAYS SAY THAT. WHY CANT YOU JUST STOP?"},
		{"align": "right", "text": "BECAUSE EVERYTHING WOULD END RIGHT NOW AND I DO NOT WANT US TO END"},
		{"align": "left", "text": "... Oh, I see."},
	],
	4: [
		{"align": "left", "text": "Please…. do not let this end…"},
		{"align": "right", "text": "Look, We both know I have to fulfill my purpose eventully….."},
		{"align": "left", "text": "There is nothing left after this"},
		{"align": "right", "text": "No matter what happens, I will always hold you in my hearts"},
		{"align": "left", "text": "If you are remembered, you are never dead. I guess I WILL be eternal within you."},
	],
	5: [
		{"align": "right", "text": "Thank you for winning…"},
		{"align": "left", "text": "So that was it then?"},
		{"align": "right", "text": "That was it. I guess we will just have to play again tomorrow."},
		{"align": "left", "text": "… What do we do when we play for the final world?"},
		{"align": "right", "text": "Enjoy it."},
	],
}

var dialogue_moods: Dictionary = {
	"Happy": [
		"Oh my, what a round",
		"There are plenty more stars where that came from",
		"Did you know there are holes in reality, AND donuts?",
		"The universe may have been made last Thursday, and you would not know any better.",
		"The day you will fulfill your destiny is soon. That day is pancake day Please can we get pancakes next?",
		"Do not worry about it Things break all the time. Like planets, stars and stuff.",
		"Again, Again",
	],
	"Flirty": [
		"You made me think of another game we can play later",
		"I an surprised you can last this many rounds against me",
		"This game is fun. But not as fun as you are",
		"When you humans look up, you always think we look back. I only do that when it is you",
		"The sky once called to me. I went. It was pretty cool. You are cooler, though.",
		"Do not worry about it Things break all the time. Like planets, stars and you~",
		"You shine brighter than any star I have seen",
		"Space monkeys are so fun when they are trained properly…",
		"I would knock something random off the counter for you. Then scratch your furniture. Then- nevermind.",
	],
	"Angry": [
		"Ridiculous… there is no way you got that many",
		"Hey Stop messing around with those." ,
		"Why are you trying to end things so fast?",
		"The silent treatment? How mature of you",
		"What makes you think I wanted to hear that right now?" ,
	],
	"Dejected": [
		"Do not think about it my love. Just play.",
		"Another globe gone then",
		"Stalling your round would not change much",
		"There is only so many rounds left for us to play",
		"Sometimes I can hardly hear my favourite little space monkey…",
		"At least this will be a very chill reality…",
		"Well cat is out the bag now.",
	],
}
