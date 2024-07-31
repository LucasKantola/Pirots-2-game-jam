extends Object

class_name RoomState

var room: Room
var nodes: Dictionary = {}

static func get_state(room: Room) -> RoomState:
    var state = RoomState.new()
    state.room = room
    state.add_node(room)
    return state

func add_node(node: Node2D) -> void:
    if node.is_in_group("RoomResetExcluded"):
        return
    var path = room.get_path_to(node)
    var nodeState = NodeState.get_state(node)
    nodes[path] = nodeState
    for child in node.get_children():
        if not child is Node2D:
            push_warning("%s is not a node and cannot be saved" % child)
            continue
        self.add_node(child)

func apply(room: Room) -> void:
    if room != self.room:
        push_warning("Applying room state to a different room")
    for path in nodes:
        if not room.has_node(path):
            push_error("%s no longer exists and cannot be reset" % path)
            continue
        var node = room.get_node(path)
        if node.is_in_group("RoomResetExcluded"):
            continue
        var state = nodes[path]
        state.apply(node)

class NodeState:
    @export var properties: Dictionary = {}
    
    static func get_state(node: Node2D) -> NodeState:
        var state = NodeState.new()
        for property in node.get_property_list():
            state.properties[property.name] = node.get(property.name)
        return state
    
    func apply(node: Node2D) -> void:
        for property in properties:
            node.set(property, properties[property])
