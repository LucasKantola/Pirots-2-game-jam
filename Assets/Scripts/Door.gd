@tool
extends SnapPosition

## A door will send the player to another room when touched.

#region Exported variables
@export var enabled: bool = true
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

func _on_door_area_body_entered(body):
    if not enabled:
        return
    
    if body.name == "Player":
        # Load new room
        var newRoom = load(destinationScenePath)
        if not newRoom is PackedScene:
            print("Failed to load scene: " + destinationScenePath)
            return
        newRoom = newRoom as PackedScene
        newRoom.instantiate()
        # Position new room
        # TODO
        # Disable door
        enabled = false

func _process(delta):
    super._process(delta)
    if Engine.is_editor_hint():
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
        

enum Face {
    LEFT,
    RIGHT,
    UP,
    DOWN,
}
