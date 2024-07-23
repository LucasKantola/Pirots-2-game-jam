extends Camera2D

#region Public variables
@export var transitionDurationSeconds: float = 1.0
#region Debug variables
@export_group("Debug")
@export var followPlayer := false
#endregion
#endregion

#region References
@onready var world = $".."
@onready var player = $"../Player"
#endregion

var t := 0.0
var targetRoom: Room:
    set(value):
        oldFit = fit
        t = 0.0
        targetRoom = value
    get:
        return targetRoom
var oldFit: Vector3

## A vector representing the position and zoom of a camera. Zoom is uniform.
var fit: Vector3:
    set(value):
        position = Vector2(value.x, value.y)
        zoom = Vector2(value.z, value.z)
    get:
        return Vector3(position.x, position.y, zoom.x)

func _ready():
    get_viewport().connect("size_changed", snap_to_room)

func _process(delta):
    if followPlayer:
        position = player.position
    else:
        var roomFit = get_room_fit(targetRoom)
        var diffFit = roomFit - oldFit
        if diffFit != Vector3.ZERO:
            t = clamp(t + delta / transitionDurationSeconds, 0, 1)
            fit = oldFit + diffFit * ease(t, -2.0)
            
            if t >= 1:
                oldFit = roomFit
                t = 0

func snap_to_room():
    var roomFit = get_room_fit(targetRoom)
    fit = roomFit
    oldFit = roomFit

func get_room_fit(room: Room) -> Vector3:
    var size = room.get_node("RoomShape").size as Vector2
    var position: Vector2 = room.get_node("RoomShape").global_position + size / 2
    var zoom: float = min(get_viewport().get_visible_rect().size.x / size.x,
            get_viewport().get_visible_rect().size.y / size.y)
    return Vector3(position.x, position.y, zoom)
