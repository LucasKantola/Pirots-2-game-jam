extends Node2D

@onready var sprite = $Sprite2D
@onready var collider = $Area2D/CollisionShape2D
@export var maxHeight = 100
@export var growthRate = 1.1

var currentHeight

@export var platforms: Array = [
    {
        "position": Vector2(10, 20),
        "size": Vector2(20, 10),
        "texture": "res://Assets/Sprites/Sprite-0006.png",
        "rendered": false
    },
    {
        "position": Vector2(-10, 40),
        "size": Vector2(20, 10),
        "texture": "res://Assets/Sprites/Sprite-0006.png",
        "rendered": false
    }
]


func _ready():
    currentHeight = sprite.get_rect().size.y

func bodyEntered(body: Node2D) -> void:
    if body.is_in_group("Drop"):
        if currentHeight < maxHeight:
            currentHeight *= growthRate
            sprite.scale.y *= growthRate
            sprite.position.y -= currentHeight * (growthRate - 1)

        for platform in platforms:
            if currentHeight >= platform["position"].y:
                if not platform["rendered"]:
                    platform["rendered"] = true
                    var platformSprite = Sprite2D.new()
                    platformSprite.texture = load(platform["texture"])
                    platformSprite.position = platform["position"]
                    platformSprite.scale = platform["size"]
                    add_child(platformSprite)
