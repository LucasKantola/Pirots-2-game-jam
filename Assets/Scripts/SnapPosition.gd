@tool
extends Node2D

class_name SnapPosition

@export var gridSize: int = 16

func _process(delta):
    if Engine.is_editor_hint():
        # Snap to grid
        $".".position = snap_vector_to_grid($".".position)
    
func snap_vector_to_grid(value: Vector2) -> Vector2:
    return Vector2(snap_to_grid(value.x), snap_to_grid(value.y))
    
func snap_to_grid(value: float) -> float:
    return floor(value / gridSize) * gridSize
