@tool
extends StaticBody2D

class_name ConditionGate

#region Public variables
## How many frames to wait between each check
@export var checkFrequency := 10
#region Position variables
@export_group("Position")
@export var size := Vector2i(1, 1)
@export_range(1, INF, 1, "or_greater") var gridSize: int = 16
#endregion
#region Editor variables
@export_group("Editor")
@export var debugColor := Color.TRANSPARENT
#endregion

var frameCount := 0

func _ready():
    if not Engine.is_editor_hint():
        update_shape()

func _process(delta):
    if Engine.is_editor_hint():
        update_shape()
    else:
        frameCount += 1
        if frameCount >= checkFrequency:
            frameCount = 0
            check_condition()

func update_shape():
    var sprite: Sprite2D = get_node("Sprite2D")
    var collision: CollisionShape2D = get_node("Collision")
    var rect = RectangleShape2D.new()
    
    rect.extents = size * gridSize * 0.5
    collision.shape = rect
    sprite.scale = 2 * rect.extents / sprite.texture.get_size()
    
    collision.position = rect.extents
    sprite.position = collision.position
    
    # Set debug color
    collision.debug_color = debugColor

## Override in subclasses.
func check_condition() -> void:
    pass

func open(delete: bool = true) -> void:
    $Open.play()
    if delete:
        queue_free()
    else:
        $Collision.disabled = true
        visible = false

func close() -> void:
    $Collision.disabled = false
    visible = true
    
func _draw():
    var hitbox = $Collision
    draw_rect(Rect2(hitbox.position.x - hitbox.shape.size.x / 2, hitbox.position.y - hitbox.shape.size.y / 2, hitbox.shape.size.x, hitbox.shape.size.y), Color(0, 1, 0, 0.5))
