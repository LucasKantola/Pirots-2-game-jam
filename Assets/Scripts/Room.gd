extends Node2D

class_name Room

@export var right: PackedScene
@export var left: PackedScene
@export var up: PackedScene
@export var down: PackedScene


func _on_room_area_body_exited(body):
    print("Exit")
