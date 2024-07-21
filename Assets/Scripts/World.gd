extends Node2D

#region Public variables
#region Rooms variables
@export_group("Rooms")
@export_range(0, 1, 0.1, "or_greater") var transitionDurationSeconds := 1.0
#endregion
#endregion

#region References
@onready var player = $Player
#endregion

var currentRoom: Node2D
var fadingRooms: Array[Node2D]
var appearingRooms: Array[Node2D]

func _ready():
    currentRoom = $Rooms.get_children()[0]

func _process(delta):
    # Fading rooms
    for room in fadingRooms:
        var modulate: Color = room.modulate
        if transitionDurationSeconds == 0:
            modulate.a = 0
        else:
            modulate.a = clamp(modulate.a - delta / transitionDurationSeconds, 0, 1)
        room.modulate = modulate
        if modulate.a == 0:
            fadingRooms.erase(room)
            
    # Appearing rooms
    for room in appearingRooms:
        var modulate: Color = room.modulate
        if transitionDurationSeconds == 0:
            modulate.a = 1
        else:
            modulate.a = clamp(modulate.a + delta / transitionDurationSeconds, 0, 1)
        room.modulate = modulate
        if modulate.a == 1:
            appearingRooms.erase(room)

func enter_door(door: Door) -> void:
    print("Entering room " + door.destinationScenePath)
    # Create room if needed
    var destinationExists: bool = not not door.destinationRoom
    if not destinationExists:
        print("Instantiating room")
        createDoorDestination(door)
    # Get destination door
    var destinationRoom = door.destinationRoom
    var destinationDoor = door.destinationDoor
    # Transition to new room
    destinationDoor.disabled = true
    destinationRoom.process_mode = PROCESS_MODE_INHERIT
    currentRoom.process_mode = PROCESS_MODE_DISABLED
    
    fade(currentRoom)
    if not destinationExists:
        destinationRoom.modulate.a = 0
    appear(destinationRoom)
    
    currentRoom = destinationRoom

func fade(x: Node2D):
    fadingRooms.append(x)
    if x in appearingRooms:
        appearingRooms.erase(x)

func appear(x: Node2D):
    appearingRooms.append(x)
    if x in fadingRooms:
        fadingRooms.erase(x)

func createDoorDestination(door: Door) -> void:
    # Intantiate scene
    var scene = load(door.destinationScenePath)
    if not scene is PackedScene:
        print("Failed to load scene: " + door.destinationScenePath)
        return
    scene = scene as PackedScene
    var newRoom = scene.instantiate()
    $Rooms.add_child(newRoom)
    # Find destination door
    var destinationFaceDoors = []
    for d in get_tree().get_nodes_in_group("door"):
        d = d as Door
        if newRoom.is_ancestor_of(d) and d.face == door.opposite_face:
            destinationFaceDoors.append(d)
    var destinationDoor = destinationFaceDoors[door.destinationIndex]
    destinationDoor.disabled = true
    # Position new room
    newRoom.position = currentRoom.position + door.position - destinationDoor.position
    
    door.destinationRoom = newRoom
    door.destinationDoor = destinationDoor

func exit_door(door: Door) -> void:
    door.disabled = false
