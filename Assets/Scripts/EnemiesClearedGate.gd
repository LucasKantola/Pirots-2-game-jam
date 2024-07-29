@tool
extends ConditionGate

class_name EnemiesClearedGate

#region References
@onready var parentRoom: Room = $".."
#endregion

func check_condition():
    var aliveEnemiesInRoom = get_tree().get_nodes_in_group("enemy").filter(func (x):
        return parentRoom.is_ancestor_of(x) and not (x as Enemy).isDead
        )
    if aliveEnemiesInRoom.is_empty():
        # All enemies are dead
        open()
