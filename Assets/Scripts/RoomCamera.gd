extends Node2D

func _ready():
    fit_to_room()

func _process(delta):
    fit_to_room()

func fit_to_room():
    $".".position = $"../RoomArea/RoomShape".position
    var shape = $"../RoomArea/RoomShape".shape as RectangleShape2D
    var z = min(get_viewport().get_visible_rect().size.x / shape.get_rect().size.x,
            get_viewport().get_visible_rect().size.y / shape.get_rect().size.y)
    $".".zoom = Vector2(z, z)
