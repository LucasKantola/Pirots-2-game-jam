@tool
extends StaticBody2D

class_name ConditionGate

#region Public variables
#region Position variables
@export_group("")
@export var size := Vector2i(1, 1)
@export_range(1, INF, 1, "or_greater") var gridSize: int = 16
#endregion
#region Editor variables
@export_group("Editor")
@export var debugColor := Color.TRANSPARENT
#endregion

func _ready():
    if not Engine.is_editor_hint():
        update_shape()

func _process(delta):
    if Engine.is_editor_hint():
        update_shape()

func update_shape():
    var sprite: Sprite2D = $Sprite2D
    var collision: CollisionShape2D = $Collision
    var rect = RectangleShape2D.new()
    
    rect.extents = size * gridSize * 0.5
    collision.shape = rect
    sprite.scale = 2 * rect.extents / sprite.texture.get_size()
    
    collision.position = rect.extents
    sprite.position = collision.position
    
    # Set debug color
    collision.debug_color = debugColor

func open(delete: bool = true):
    await $Open.play()
    if delete:
        queue_free()
    else:
        $Collision.disabled = true
        visible = false

func close():
    $Collision.disabled = false
    visible = true
    
