extends Node

func distance(point_a : Vector2, point_b : Vector2) -> float:
	return abs(sqrt(pow(point_a.x - point_b.x, 2) + pow(point_a.y - point_b.y, 2)))