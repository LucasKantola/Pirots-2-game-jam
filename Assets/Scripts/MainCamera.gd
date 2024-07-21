extends Camera2D

#region Public variables
@export var currentRoom: Node2D
@export var transitionDurationSeconds: float = 1.0
#region Debug variables
@export_group("Debug")
@export var followPlayer := false
#endregion
#endregion

var t := 0.0
var oldFit: Vector3

func _ready():
    if not followPlayer:
        var fit = get_room_fit(currentRoom)
        global_position = Vector2(fit.x, fit.y)
        zoom = Vector2(fit.z, fit.z)
        oldFit = fit

func _process(delta):
    if followPlayer:
        position = $"../Player".position
    else:
        var fit = get_room_fit(currentRoom)
        var diffFit = fit - oldFit
        if diffFit != Vector3.ZERO:
            t = clamp(t + delta / transitionDurationSeconds, 0, 1)
            var midFit = oldFit + diffFit * ease(t, -2.0)
            global_position = Vector2(midFit.x, midFit.y)
            zoom = Vector2(midFit.z, midFit.z)
            
            if t >= 1:
                oldFit = fit
                t = 0

func get_room_fit(room: Node2D) -> Vector3:
    var size = room.get_node("RoomShape").size as Vector2
    var position: Vector2 = room.get_node("RoomShape").global_position + size / 2
    var zoom: float = min(get_viewport().get_visible_rect().size.x / size.x,
            get_viewport().get_visible_rect().size.y / size.y)
    return Vector3(position.x, position.y, zoom)
