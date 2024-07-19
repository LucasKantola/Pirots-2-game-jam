extends Node2D

@onready var sprite = $Sprite2D
@onready var collider = $Area2D/CollisionShape2D
@export var maxHeight = 100
@export var growthRate = 1.1
@export var defaultOffset := 10.0

var currentHeight

@export var branchScene: PackedScene = load("res://Assets/Scenes/Branch.tscn") 

@export var platforms: Array = [
    {
        "position": Vector2(10, 20),
        "rendered": false
    },
    {
        "position": Vector2(-10, 40),
        "rendered": false
    }
]

func _ready():
    currentHeight = sprite.get_rect().size.y

func bodyEntered(body: Node2D) -> void:
    if body.is_in_group("Drop"):
        if currentHeight < maxHeight:
            var lastHeight = currentHeight
            currentHeight *= growthRate
            sprite.scale.y *= growthRate
            sprite.position.y -= (currentHeight - lastHeight) / 2

        for platform in platforms:
            if currentHeight >= platform["position"].y:
                if not platform["rendered"]:
                    platform["rendered"] = true
                    var platformScene = branchScene.instantiate()
                    platformScene.position = Vector2(platform["position"].x, platform["position"].y * -1)
                    add_child(platformScene)
    queue_redraw()

func _draw():
    for platform in platforms:
        if currentHeight >= platform["position"].y - defaultOffset:
            var bottomPos = Vector2(0, -platform["position"].y + defaultOffset)
            print("bottomPos: ", bottomPos)
            var topPos = platform["position"]
            
            # Calculate the direction vector and the maximum distance the line can grow
            var direction = bottomPos.direction_to(platform["position"])
            var maxDistance = min(currentHeight, bottomPos.distance_to(platform["position"]))
            
            # Calculate the end point of the line based on the max distance
            var endPos = bottomPos + direction * maxDistance
            endPos.y *= -1
            
            draw_line(bottomPos, endPos, Color(1, 1, 1), 1)
