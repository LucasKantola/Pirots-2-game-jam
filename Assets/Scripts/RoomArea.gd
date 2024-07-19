@tool
extends Node2D

@export var gridSize: int = 1
@export var leftDoors: Array[Vector2i]
@export var rightDoors: Array[Vector2i]
@export var upDoors: Array[Vector2i]
@export var downDoors: Array[Vector2i]

@export var doorDebugColor: Color = Color(0.5, 0.25, 0, 0.5)

var oldExtents: Vector2

func _process(delta):
    if Engine.is_editor_hint():
        # Snap to grid
        var rect = $".".shape as RectangleShape2D
        var position = $".".position
        
        var a = snap_vector_to_grid(position - rect.extents)
        var b = snap_vector_to_grid(position + rect.extents)
        
        var width = abs(a.x - b.x)
        var height = abs(a.y - b.y)
        
        var centerX = (a.x + b.x) / 2
        var centerY = (a.y + b.y) / 2
        
        rect.extents = Vector2(width / 2, height / 2)
        $".".shape = rect
        position = Vector2(centerX, centerY)
        $".".position = position
        
        # Regenerate doors
        if rect.extents != oldExtents:
            generate_doors(
                $"./Doors/Left",
                leftDoors,
                Vector2(-rect.extents.x - gridSize/2, -rect.extents.y + gridSize/2),
                Vector2(0, 1)
            )
            generate_doors(
                $"./Doors/Right",
                rightDoors,
                Vector2(+rect.extents.x + gridSize/2, -rect.extents.y + gridSize/2),
                Vector2(0, 1)
            )
            generate_doors(
                $"./Doors/Up",
                upDoors,
                Vector2(-rect.extents.x + gridSize/2, -rect.extents.y - gridSize/2),
                Vector2(1, 0)
            )
            generate_doors(
                $"./Doors/Down",
                downDoors,
                Vector2(-rect.extents.x + gridSize/2, +rect.extents.y + gridSize/2),
                Vector2(1, 0)
            )
        
        oldExtents = rect.extents
    
func snap_vector_to_grid(value: Vector2) -> Vector2:
    return Vector2(snap_to_grid(value.x), snap_to_grid(value.y))
    
func snap_to_grid(value: float) -> float:
    return floor(value / gridSize) * gridSize

func generate_doors(parent: Node2D, doors: Array[Vector2i], startPosition: Vector2, direction: Vector2) -> void:
    # Clear parent
    for node in parent.get_children():
        parent.remove_child(node)
    
    var rect = $".".shape as RectangleShape2D
    var position = $".".position
    
    var doorScene = preload("res://Assets/Scenes/Door.tscn")
    for i in range(doors.size()):
        var doorInstance = doorScene.instantiate()
        var collision = doorInstance.get_node("./DoorArea/CollisionShape2D") as CollisionShape2D
        var doorRect = RectangleShape2D.new()
        
        var startTile = doors[i].x
        var endTile = doors[i].x + doors[i].y
        
        doorInstance.position = startPosition + direction * (startTile + endTile) / 2 * gridSize
        doorRect.extents = (Vector2(gridSize, gridSize) + direction * doors[i].y * gridSize) / 2
        
        collision.shape = doorRect
        collision.debug_color = doorDebugColor
        parent.add_child(doorInstance)
