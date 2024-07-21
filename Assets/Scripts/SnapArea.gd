@tool
extends SnapPosition

class_name SnapArea

func _process(delta):
    if Engine.is_editor_hint():
        # Snap to grid
        var rect = $".".shape as RectangleShape2D
        var position = $".".position
        
        var a = snap_vector_to_grid(position - rect.extents)
        var b = snap_vector_to_grid(position + rect.extents)
        
        var width = abs(a.x - b.x)
        var height = abs(a.y - b.y)
        
        var centerX = (a.x + b.x) / 2
        var centerY = (a.y + b.y) / 2
        
        rect.extents = Vector2(width / 2, height / 2)
        $".".shape = rect
        position = Vector2(centerX, centerY)
        $".".position = position
