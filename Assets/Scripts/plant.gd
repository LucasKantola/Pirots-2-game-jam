extends Node2D

var maxHeight = 100

func bodyEntered(body: Node2D) -> void:
    print_debug("bodyEntered" + body.name)
    print(str(body))