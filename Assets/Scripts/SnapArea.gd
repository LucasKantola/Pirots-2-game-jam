@tool
extends Node2D

@export var gridSize: int = 1

var previousExtents

func _process(delta):
    if Engine.is_editor_hint():
        var rect = $".".shape as RectangleShape2D
        var position = $".".position
        
        var a = snap_vector_to_grid(position - rect.extents)
        var b = snap_vector_to_grid(position + rect.extents)
        
        var width = abs(a.x - b.x)
        var height = abs(a.y - b.y)
        
        var centerX = (a.x + b.x) / 2
        var centerY = (a.y + b.y) / 2
        
        if previousExtents != rect.extents:
            rect.extents = Vector2(width / 2, height / 2)
        previousExtents = rect.extents
        $".".shape = rect
        $".".position = Vector2(centerX, centerY)
    
func snap_vector_to_grid(value: Vector2) -> Vector2:
    return Vector2(snap_to_grid(value.x), snap_to_grid(value.y))
    
func snap_to_grid(value: float) -> float:
    var fract = fmod(value, gridSize)
    var t = floor(value / gridSize) + round(fract / gridSize)
    return t * gridSize
