extends Node2D

func _on_door_area_body_entered(body):
    if body.name == "Player":
        print("Player exited room")
