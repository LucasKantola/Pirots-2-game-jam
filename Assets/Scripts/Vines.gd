extends Node2D
# The Plant script is responsible for the growth of the plant. 
# It listens for the bodyEntered signal and checks if the body is a Drop node and if it is a LAVA drop. 
# If it is, it starts the timer. The timer is responsible for the burning effect. When the timer finishes, the plant is destroyed. 


@export var burnTime := 2.0
@export var fireNeeded := 10
var timer: Timer

func _ready():
    timer = $Timer

    if not timer: 
        push_error("Timer node not found")

func bodyEntered(body: Node) -> void:
    if body.is_in_group("Drop"):
        if body.dropType == body.DropType.LAVA:
            fireNeeded -= 1
            if fireNeeded <= 0:
                if not timer.is_connected("timeout", Callable(self, "burningFinished")):
                    timer.start(burnTime)
                    timer.connect("timeout", Callable(self, "burningFinished"))

func burningFinished():
    queue_free()