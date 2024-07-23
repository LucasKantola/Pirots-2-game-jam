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

var currentRoom: Room

func _ready():
    currentRoom = $Rooms.get_children()[0] as Room

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
    currentRoom.disappear()
    destinationRoom.appear()
    
    currentRoom = destinationRoom

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
