extends Node2D

@onready var stalk = $Stalk
@onready var roots = $Roots

@onready var collider = $Area2D/CollisionShape2D
@export var maxHeight = 100
@export var growthRate = 1.1
@export var defaultOffset := 10.0

var currentHeight: float

@export var branchScene: PackedScene = load("res://Assets/Scenes/Branch.tscn") 

@export var platforms: Array = [
    {
        "position": Vector2(30, 90),
        "rendered": false
    },
    {
        "position": Vector2(-40, 40),
        "rendered": false
    }
]

func _ready():
    currentHeight = stalk.get_rect().size.y

func bodyEntered(body: Node2D) -> void:
    if body.is_in_group("Drop"):
        if currentHeight < maxHeight:
            var lastHeight = currentHeight
            currentHeight *= growthRate
            stalk.position.y -= (currentHeight - lastHeight) / 2
            stalk.texture.region.size.y += currentHeight-lastHeight
            stalk.texture.region.position.y -= (currentHeight - lastHeight)

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
            
            # Calculate the direction vector and the maximum distance the line can grow
            var direction = bottomPos.direction_to(platform["position"])
            var maxDistance = min(currentHeight, bottomPos.distance_to(platform["position"]))
            
            # Calculate the end point of the line based on the max distance
            var endPos = bottomPos + direction * maxDistance
            endPos.y = -endPos.y
        
            draw_dashed_line(bottomPos, endPos, Color(11, 88, 110, 1), 3)
