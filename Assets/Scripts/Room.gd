extends Node2D

class_name Room

#region Public variables
@export_color_no_alpha var coverColor := Color.BLACK
#region Transition variables
@export_group("Transition")
@export_range(0, 3, 0.1, "or_greater") var transitionDurationSeconds: float = 1.0
#endregion
#region Camera variables
@export_group("Camera")
### If the camera should follow the player instead of the room.
@export var followPlayer := false
### How much to zoom in when the followPlayer is true. 1.0 means the room will
### fill the viewport.
@export_range(0.1, 3, 0.1, "or_greater") var followZoom: float = 1.0
### If the camera should be limited to the edges of the room.
@export var followLimitByRoomShape := true
#endregion
#endregion

var cover
var transitionState := TransitionState.NONE
var t := 1.0

func _ready():
    cover = generate_cover_polygon()
    $RoomShape.add_child(cover)

func _process(delta):
    if transitionState == TransitionState.NONE:
        return
    elif transitionState == TransitionState.APPEARING:
        if transitionDurationSeconds == 0:
            t = 1.0
        else:
            t += delta / transitionDurationSeconds
        if t >= 1.0:
            # Done appearing
            transitionState = TransitionState.NONE
            t = 1.0
            # Enable doors
            for door in get_tree().get_nodes_in_group("door"):
                if $".".is_ancestor_of(door):
                    door.disabled = false
    elif transitionState == TransitionState.DISAPPEARING:
        if transitionDurationSeconds == 0:
            t = 0.0
        else:
            t -= delta / transitionDurationSeconds
        if t <= 0.0:
            # Done disappearing
            transitionState = TransitionState.NONE
            t = 0.0
            process_mode = PROCESS_MODE_DISABLED
    
    cover.set_deferred("color", Color(coverColor, 1-t))
    
func disappear():
    if t == 0.0:
        t = 1.0
    transitionState = TransitionState.DISAPPEARING
    # Disable doors
    for door in get_tree().get_nodes_in_group("door"):
        if $".".is_ancestor_of(door):
            door.disabled = true

func appear():
    if t == 1.0:
        t = 0.0
    process_mode = PROCESS_MODE_INHERIT
    transitionState = TransitionState.APPEARING

func disappear_instant():
    disappear()
    t = 0.0

func appear_instant():
    appear()
    t = 1.0

enum TransitionState {
    NONE,
    APPEARING,
    DISAPPEARING,
}

func generate_cover_polygon() -> Polygon2D:
    var terrain: TileMap = $RoomShape/Terrain
    var background: TileMap = $RoomShape/Background
    
    var shapeMap = []
    var shape = $RoomShape
    var dimensions = shape.size / terrain.rendering_quadrant_size

    var startCell: Vector2i
    for x in range(dimensions.x):
        shapeMap.append([])
        for y in range(dimensions.y):
            var coords = Vector2i(x, y)
            var hasCell: bool = (terrain.get_cell_source_id(0, coords) != -1
                    or background.get_cell_source_id(0, coords) != -1)
            if hasCell and not startCell:
                startCell = Vector2i(x, y)
            shapeMap[x].append(hasCell)
    
    var sb = ""
    for y in range(dimensions.y):
        for x in range(dimensions.x):
            sb += 'X' if shapeMap[x][y] else ' '
        sb += '\n'
    print(sb)
    
    # Create perimeter
    var perimeter = []
    var currentCell := startCell
    var lastCell: Vector2i
    var neighborOffsets = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0)]
        
    while true:
        var loneliestNeighbor: Vector2i
        var loneliestNeighborCount: int = 8
        for offset in neighborOffsets:
            var coord = currentCell + offset
            if (is_outside_dimensions(dimensions, coord)
                    or not shapeMap[coord.x][coord.y] 
                    or coord == lastCell):
                continue
            var neighbors = get_neighbor_count(shapeMap, dimensions, coord)
            
            #print("%d %d" % [neighbors, loneliestNeighborCount])
            if neighbors < loneliestNeighborCount:
                loneliestNeighbor = coord
                #print("New loneliest: %s" % loneliestNeighbor)
                loneliestNeighborCount = neighbors
        
        #print(currentCell)
        if loneliestNeighborCount == 8:
            print("WARNING: Room perimeter ran into a dead end")
            break
        if currentCell in perimeter:
            print("WARNING: Loop detected in room perimiter!")
            break
        perimeter.append(currentCell)
        lastCell = currentCell
        currentCell = loneliestNeighbor
        if currentCell == startCell:
            break
        
    
    #sb = ""
    #for y in range(dimensions.y):
        #for x in range(dimensions.x):
            #sb += 'P' if (Vector2i(x, y) in perimeter) else ' '
        #sb += '\n'
    #print(sb)
    
    var poly = Polygon2D.new()
    #poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(128, 0), Vector2(128, 48)])
    #print(poly.polygon)
    poly.name = "Cover"
    poly.z_index = 1
    poly.color = Color(coverColor, 0.0)
    return poly

func is_outside_dimensions(dimensions: Vector2i, cell: Vector2i) -> bool:
    return (cell.x < 0 or cell.x >= dimensions.x
            or cell.y < 0 or cell.y >= dimensions.y)

func get_neighbor_count(shapeMap: Array, dimensions: Vector2i, cell: Vector2i) -> int:
    var neighborOffsets = [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)]
    if not shapeMap[cell.x][cell.y]:
        return INF
    var neighbors = 0
    for offset in neighborOffsets:
        var coord = cell + offset
        if is_outside_dimensions(dimensions, coord):
            continue
        if shapeMap[coord.x][coord.y]:
            neighbors += 1
    return neighbors
