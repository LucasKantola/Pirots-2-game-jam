extends Node2D

#region Public variables
#region Rooms variables
@export_group("Rooms")
@export_range(0, 10, 0.1, "or_greater") var fadeDurationSeconds := 1.0
#endregion
#endregion

var currentRoom: Node2D
var fadingRooms: Array[Node2D]

func _ready():
    print("World ready")
    currentRoom = $Rooms.get_children()[0]

func _process(delta):
    for i in range(fadingRooms.size()):
        if i >= fadingRooms.size():
            break
        var room = fadingRooms[i]
        var modulate: Color = room.modulate
        if fadeDurationSeconds == 0:
            modulate.a = 0
        else:
            modulate.a -= delta / fadeDurationSeconds
        if modulate.a <= 0:
            print("Deleting " + room.to_string())
            fadingRooms.remove_at(i)
            room.queue_free()
        else:
            room.modulate = modulate

func enter_door(door: Door) -> void:
    print("Entering room " + door.destinationScenePath)
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
    # Disable current room's doors
    for d in get_tree().get_nodes_in_group("door"):
        if currentRoom.is_ancestor_of(d):
            d.disabled = true
    # Start fading current room
    fadingRooms.append(currentRoom)
    # Set new room to current room
    currentRoom = newRoom

func exit_door(door: Door) -> void:
    if currentRoom.is_ancestor_of(door):
        door.disabled = false
