extends Node2D

@onready var sprite = $Sprite2D
@onready var collider = $Area2D/CollisionShape2D
var maxHeight = 100

func bodyEntered(body: Node2D) -> void:
    print_debug("bodyEntered" + body.name)
    print(str(body))

    if body.is_in_group("Drop"):        
        if sprite.get_rect().size.y < maxHeight:
            sprite.position.y -= sprite.get_rect().size.y / 2
            sprite.scale.y += 1
            collider.position.y -= collider.shape.size.y / 2