extends Node2D


signal build(world_position, target)
signal build_complete()


enum State {
    Idle,
    Placing,
}


onready var tile_map: TileMap = $"../TileMap"

var state: int = State.Idle
var size: Vector2
var pos: Vector2
var can_place: bool = false
var build_tower: Tower
var occupied_tiles: Dictionary = {}
var towers: Array = []


func building(tower):
    tower.start_building()


func _on_build_complete():
    emit_signal("build_complete")


func _unhandled_input(event: InputEvent):
    match state:
        State.Placing:
            if event is InputEventMouseMotion:
                var mouse_pos := get_global_mouse_position()
                set_pos(quantise_to_grid(mouse_pos))
                can_place = check_pos_is_buildable(mouse_pos)

            if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
                var mouse_pos := get_global_mouse_position()
                set_pos(quantise_to_grid(mouse_pos))
                can_place = check_pos_is_buildable(mouse_pos)
                state = State.Idle
                end()
                if can_place:
                    place_tower(get_global_mouse_position())

        State.Idle:
            var mouse_pos := get_global_mouse_position()

            # if state is NOT placing but the player clicked on an unbuilt tower, then
            # they should resume
            if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
                for t in towers:
                    if t.state != Tower.State.Active and t.contains_point(mouse_pos):
                        emit_signal("build", t.build_position(), t)


func place_tower(pos_: Vector2):
    build_tower.position = quantise_to_grid(pos_)

    towers.append(build_tower)
    $"../YSort".add_child(build_tower)
    var err := build_tower.connect("build_complete", self, "_on_build_complete"); assert(err == 0)

    var top_left_pos := tile_map_pos(pos_)
    var size_ = build_tower.tile_size

    for x in range(top_left_pos.x, top_left_pos.x + size_.x):
        for y in range(top_left_pos.y, top_left_pos.y + size_.y):
            var p := Vector2(x, y)
            occupied_tiles[p] = null

    emit_signal("build", build_tower.build_position(), build_tower)


func check_pos_is_buildable(pos_: Vector2) -> bool:
    var top_left_pos := tile_map_pos(pos_)
    var size_ = build_tower.tile_size

    for x in range(top_left_pos.x, top_left_pos.x + size_.x):
        for y in range(top_left_pos.y, top_left_pos.y + size_.y):
            var p := Vector2(x, y)
            if p in occupied_tiles:
                return false

            if not tile_map.is_tile_placeable(x, y):
                return false

    return true


func _on_player_state_changed(state_):
    if state_ != Player.States.BUILDING:
        for t in towers:
            t.stop_building()



func _draw():
    if state == State.Placing:
        var color = Color(0, 1, 0, 1) if can_place else Color(1, 0, 0, 1)
        draw_rect(Rect2(pos, size), color, false)


func tile_map_pos(x: Vector2) -> Vector2:
    return tile_map.world_to_map(x - size/2 + tile_map.cell_size/2)


func quantise_to_grid(x) -> Vector2:
    return tile_map.map_to_world(tile_map_pos(x))


func on_build_requested(kind: String):
    build_tower = Globals.TOWERS[kind]["scene"].instance()

    # apply params
    var params: Dictionary = Globals.TOWERS[kind]["params"]
    build_tower.kind = kind
    for param in params:
        build_tower.set(param, params[param])

    state = State.Placing
    size = build_tower.tile_size * tile_map.cell_size
    update()


func end():
    update()


func set_pos(pos_: Vector2):
    # Quantise the position
    self.pos = pos_
    update()
