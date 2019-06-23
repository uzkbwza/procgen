extends Node

func _process(delta):
	DEBUG.set_text("fps", Engine.get_frames_per_second())