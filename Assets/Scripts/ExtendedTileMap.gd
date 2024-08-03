extends TileMap

class_name ExtendedTileMap

## Retrieves custom data from a specific tile in the tilemap, converting
## globalPosition to a tile position and retrieves the cell data. If the cell
## data exists, it retrieves the custom data with the specified name. If the
## custom data exists, it is returned; otherwise, null is returned.
func get_custom_data_from_tilemap(layer: int, globalPositon: Vector2, dataName: String) -> Variant:
    var cellCustom
    var tilePos = local_to_map(globalPositon)
    #get the celldata from the tilemap 
    var cellData = get_cell_tile_data(layer, tilePos)
    if cellData:
        #get the custom data from the cell
        cellCustom = cellData.get_custom_data(dataName)
    if cellCustom:
        return cellCustom
    
    return null
