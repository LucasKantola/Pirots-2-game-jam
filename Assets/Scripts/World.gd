extends Node2D

class_name World

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
@onready var player: Player = $Player
@onready var playerHitbox: CollisionShape2D
@onready var camera: MainCamera = $MainCamera
@onready var worldBackground: ColorRect = $WorldBackground/ColorRect
#region Tilemaps
@onready var background: TileMap = $Background
@onready var terrain: TileMap = $Terrain
#endregion
#endregion

var gridSize: int:
    get:
        return terrain.rendering_quadrant_size

var currentRoom: Room
var lastEnteredDoor: Door
var startingPlayerState: PlayerState

func _ready():
    # References
    playerHitbox = player.get_node("Hitbox")
    # Pre-generated rooms
    currentRoom = $Rooms.get_children()[0] as Room
    setup_room(currentRoom)
    for room in $Rooms.get_children().slice(1):
        room = room as Room
        setup_room(room)
        room.disappear_instant()
    # Update camera
    camera.targetRoom = currentRoom
    camera.snap_to_room()
    # Set background color
    worldBackground.visible = true
    worldBackground.color = backgroundColor

func enter_door(door: Door) -> void:
    print("\nEntering room %s %s" % [door.destinationScenePath, door.name])
    lastEnteredDoor = door
    startingPlayerState = PlayerState.save(player)
    
    var velocity = player.velocity
    player.stopInput = true
    # Create room if needed
    var destinationExists: bool = door.check_for_destination()
    if not destinationExists:
        print("Instantiating room")
        var room = generate_door_destination(door)
        setup_room(room)
        
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
    var targetPosition = get_door_exit_position(door, currentPosition)
    
    var tween = create_tween()
    tween.tween_method(func(value): player.global_position = value, currentPosition, targetPosition, transitionDurationSeconds)
    await tween.finished
    tween.kill()
    
    player.stopInput = false
    if door.face == Door.Face.UP:
        velocity = Vector2(upExitForwardVelocity * (-1 if player.flip_h else 1), upExitVelocity)
    player.velocity = velocity
    player.move_and_slide()

func get_door_exit_position(door: Door, enterPosition: Vector2) -> Vector2:
    var targetPosition = enterPosition
    var playerExtents = (playerHitbox.shape as RectangleShape2D).extents
    match door.face:
        Door.Face.LEFT:
            targetPosition.x = door.global_position.x - playerExtents.x
        Door.Face.RIGHT:
            targetPosition.x = door.global_position.x + playerExtents.x
        Door.Face.UP:
            targetPosition.y = door.global_position.y - playerExtents.y
        Door.Face.DOWN:
            targetPosition.y = door.global_position.y + playerExtents.y
    return targetPosition

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
    return newRoom

func exit_door(door: Door) -> void:
    pass

func setup_room(room: Room) -> void:
    steal_tiles(room)
    room.coverColor = backgroundColor

func steal_tiles(room: Room) -> void:
    copy_tilemap(room, "Background", background)
    copy_tilemap(room, "Terrain", terrain)
    room.get_node("./RoomShape/Background").queue_free()
    room.get_node("./RoomShape/Terrain").queue_free()

func copy_tilemap(room: Room, fromTileMapName: String, toTileMap: TileMap) -> void:
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

func delete_room(room: Room) -> void:
    var tilemaps: Array[TileMap] = [terrain, background]
    
    var polygon: PackedVector2Array = room.cover.polygon
    var size: Vector2 = room.get_node("RoomShape").size
    var iSize: Vector2i = size / terrain.rendering_quadrant_size
    for x in range(iSize.x):
        for y in range(iSize.y):
            var coords = Vector2i(x, y)
            if Geometry2D.is_point_in_polygon(coords * gridSize, polygon):
                for tilemap in tilemaps:
                    for layer in range(tilemap.get_layers_count()):
                        var tilemapCoords = tilemap.to_local(room.to_global(coords * gridSize)) / gridSize
                        tilemap.erase_cell(layer, tilemapCoords)
    room.queue_free()

func reset_room() -> void:
    player.stopInput = true
    
    var newRoom = reload_room(currentRoom)
    currentRoom = newRoom
    # Reset player
    startingPlayerState.apply(player)
    var lastEnteredDoorCollision = lastEnteredDoor.get_node("DoorArea/CollisionShape2D")
    var doorMiddle = lastEnteredDoorCollision.global_position
    var exitPosition = get_door_exit_position(lastEnteredDoor, doorMiddle)
    player.global_position = exitPosition
    player.health = player.maxHealth
    # Update camera
    camera.targetRoom = currentRoom
    camera.snap_to_room()
    
    player.stopInput = false

func reload_room(room: Room) -> Room:
    delete_room(room)
    var scenePath = room.scene_file_path
    print(scenePath)
    var roomScene: PackedScene = load(scenePath)
    var roomInstance: Room = roomScene.instantiate()
    roomInstance.position = room.position
    $Rooms.add_child(roomInstance)
    setup_room(roomInstance)
    return roomInstance
