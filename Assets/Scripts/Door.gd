@tool
extends SnapPosition

## A door will send the player to another room when touched.
class_name Door

#region Exported variables
@export var disabled: bool = false
#region Position variables
@export_group("Position")
## Which face of the room this door is on. Doors will always lead to doors
## on the opposite face than themselves.
@export var face: Face = Face.RIGHT
## The size of the door in tiles.
@export_range (1, 10, 1, "or_greater") var size: int = 2
#endregion
#region Destination variables
@export_group("Destination")
## The scene that this door leads to.
@export_file("*.tscn") var destinationScenePath: String = "res://Assets/Scenes/Rooms/"
## Which door on the destination face this door should lead to. Should be 0
## unless there are multiple doors on the destination face. Example: Assuming
## this door's face is RIGHT, index 0 would mean the first door in the node
## hierarchy of the destination scene which has the face LEFT.
@export var destinationIndex: int = 0
#endregion
#region Editor variables
@export_group("Editor")
@export var debugColor: Color = Color(0.96, 0.6, 0.26, 0.5)
#endregion
#endregion

func _ready():
    if not Engine.is_editor_hint():
        update_shape()

func _process(delta):
    super._process(delta)
    if Engine.is_editor_hint():
        update_shape()

func update_shape():
    # Create rect
    var collision = $DoorArea/CollisionShape2D as CollisionShape2D
    var rect = RectangleShape2D.new()
    
    # Set rect extents
    rect.extents = Vector2(1, 1)
    if face == Face.LEFT or face == Face.RIGHT:
        rect.extents.y *= size
    else:
        rect.extents.x *= size
    rect.extents *= gridSize / 2
    collision.shape = rect
    
    # Set collision position
    var direction: Vector2
    match face:
        Face.LEFT:
            direction = Vector2(-1, -1)
        Face.RIGHT:
            direction = Vector2(1, -1)
        Face.UP:
            direction = Vector2(1, -1)
        Face.DOWN:
            direction = Vector2(1, 1)
    collision.position = direction * rect.extents
    
    # Set debug color
    collision.debug_color = debugColor 

func _on_door_entered(body_rid, body, body_shape_index, local_shape_index):
    if disabled:
        return
    if body.name == "Player":
        print("Entering room " + destinationScenePath + " " + ("1" if disabled else "0"))
        get_node("/root/World").enter_door($".")

func _on_door_exited(body_rid, body, body_shape_index, local_shape_index):
    if body.name == "Player":
        get_node("/root/World").exit_door($".")


enum Face {
    LEFT,
    RIGHT,
    UP,
    DOWN,
}

var opposite_face: Face:
    get:
        match face:
            Face.LEFT:
                return Face.RIGHT
            Face.RIGHT:
                return Face.LEFT
            Face.UP:
                return Face.DOWN
            Face.DOWN:
                return Face.UP
        return Face.LEFT
