extends Node2D

#region Public variables
@export_color_no_alpha var backgroundColor := Color.BLACK
#region Rooms variables
@export_group("Rooms")
@export_range(0, 1, 0.1, "or_greater") var transitionDurationSeconds := 1.0
@export_range(-1000, 0, 100, "or_greater", "or_less") var upExitVelocity := -300.0
@export_range(0, 250, 10, "or_greater", "or_less") var upExitForwardVelocity := 50.0
#endregion
#endregion

#region References
@onready var player := $Player
@onready var playerHitbox: CollisionShape2D
@onready var camera := $MainCamera
@onready var worldBackground := $WorldBackground/ColorRect
#region Tilemaps
@onready var background := $Background as TileMap
@onready var terrain := $Terrain as TileMap
#endregion
#endregion

var currentRoom: Room

func _ready():
    # References
    playerHitbox = player.get_node("Hitbox")
    # Pre-generated rooms
    currentRoom = $Rooms.get_children()[0] as Room
    steal_tiles(currentRoom)
    currentRoom.coverColor = backgroundColor
    for room in $Rooms.get_children().slice(1):
        room = room as Room
        steal_tiles(room)
        room.coverColor = backgroundColor
        room.disappear_instant()
    # Update camera
    $MainCamera.targetRoom = currentRoom
    $MainCamera.snap_to_room()
    # Set background color
    worldBackground.color = backgroundColor

func enter_door(door: Door) -> void:
    print("\nEntering room %s %s" % [door.destinationScenePath, door.name])
    var velocity = player.velocity
    player.stopInput = true
    # Create room if needed
    var destinationExists: bool = door.check_for_destination()
    if not destinationExists:
        print("Instantiating room")
        var room = generate_door_destination(door)
        steal_tiles(room)
        
    # Get destination door
    var destinationRoom = door.destinationRoom
    var destinationDoor = door.destinationDoor
    # Transition to new room
    currentRoom.disappear()
    destinationRoom.appear()
    
    currentRoom = destinationRoom
    camera.targetRoom = currentRoom
    
    print("Total rooms: %s" % $Rooms.get_children().size())
    
    # Tween player to next room
    var currentPosition = player.global_position
    var targetPosition = currentPosition
    var playerExtents = (playerHitbox.shape as RectangleShape2D).extents
    match door.face:
        Door.Face.LEFT:
            targetPosition.x = door.global_position.x
            targetPosition.x -= playerExtents.x
        Door.Face.RIGHT:
            targetPosition.x = door.global_position.x
            targetPosition.x += playerExtents.x
        Door.Face.UP:
            targetPosition.y = door.global_position.y
            targetPosition.y -= playerExtents.y
        Door.Face.DOWN:
            targetPosition.y = door.global_position.y
            targetPosition.y += playerExtents.y
    
    var tween = create_tween()
    tween.tween_method(func(value): player.global_position = value, currentPosition, targetPosition, transitionDurationSeconds)
    await tween.finished
    tween.kill()
    
    player.stopInput = false
    if door.face == Door.Face.UP:
        velocity = Vector2(upExitForwardVelocity * (-1 if player.hflipped else 1), upExitVelocity)
    player.velocity = velocity
    player.move_and_slide()

func generate_door_destination(door: Door) -> Room:
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
    
    newRoom.coverColor = backgroundColor
    return newRoom

func exit_door(door: Door) -> void:
    pass

func steal_tiles(room: Room) -> void:
    copy_tilemap(room, "Background", background)
    copy_tilemap(room, "Terrain", terrain)
    room.get_node("./RoomShape/Background").queue_free()
    room.get_node("./RoomShape/Terrain").queue_free()

func copy_tilemap(room: Room, fromTileMapName: String, toTileMap: TileMap) -> void:
    var gridSize := toTileMap.rendering_quadrant_size
    var roomTileMap = room.get_node("./RoomShape/%s" % fromTileMapName) as TileMap
    var size := (room.get_node("./RoomShape") as Control).size
    var iSize := size / gridSize
    for layer in range(roomTileMap.get_layers_count()):
        for x in range(iSize.x):
            for y in range(iSize.y):
                var roomCoords = Vector2i(x, y)
                
                var sourceId = roomTileMap.get_cell_source_id(layer, roomCoords)
                var atlasCoords := roomTileMap.get_cell_atlas_coords(layer, roomCoords)
                
                var toCoords = toTileMap.to_local(room.to_global(roomCoords * gridSize)) / gridSize
                if sourceId != -1:
                    toTileMap.set_cell(layer, toCoords, sourceId, atlasCoords)
