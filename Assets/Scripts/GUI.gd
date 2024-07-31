@tool
extends CanvasLayer

class_name GUI

#region Public variables
@export var showOnStart := true

@export_group("Health bar")
@export var health: int = 3:
    set(value):
        health = value
        update_health_bar()
    get:
        return health
#endregion

#region References
var gameOver: Control
var healthBar: Control
#endregion

func _ready():
    gameOver = get_node("GameOver")
    healthBar = get_node("HealthBar")
    update_health_bar()
    
    if not Engine.is_editor_hint():
        visible = showOnStart

func show_game_over():
    gameOver.visible = true
    
func update_health_bar():
    var missingHearts = health - healthBar.get_children().size()
    var heartTemplate = healthBar.get_child(0)
    for i in range(missingHearts):
        var newHeart = heartTemplate.duplicate()
        healthBar.add_child(newHeart)
    for i in range(healthBar.get_children().size()):
        healthBar.get_child(i).visible = i < health
