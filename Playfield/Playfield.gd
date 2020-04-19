extends Node2D


# args: (which: Globals.BARS, level: float)
signal status_changed

# args: dict[string, float]
signal inventory_updated(inventory)


onready var tower_builder: Node2D = $TowerBuilder
onready var monster: Node2D = $YSort/Monster
onready var player: Player = $YSort/Player
onready var enemies: Node2D = $YSort/Enemies


func on_build_requested(kind):
    tower_builder.on_build_requested(kind)


func _on_monster_fear_changed(fear: float) -> void:
    emit_signal("status_changed", "Fear", fear / Globals.MONSTER_MAX_FEAR)

func _on_monster_hunger_changed(hunger: float) -> void:
    emit_signal("status_changed", "Hunger", hunger)

func get_enemies_near(pos: Vector2, radius: float) -> Array:
    # TODO: Fast implementation

    var radius_squared = radius * radius
    var result := []

    for enemy in enemies.get_children():
        # assert(enemy is Enemy)
        if (enemy.position - pos).length_squared() < radius_squared:
            result.append(enemy)

    return result


func _init() -> void:
    Globals.playfield = self


func _ready():
    var err: int = 0
    err = monster.connect("fear_changed", self, "_on_monster_fear_changed"); assert(err == 0)
    err = monster.connect("hunger_changed", self, "_on_monster_hunger_changed"); assert(err == 0)

    err = tower_builder.connect("build", player, "build"); assert(err == 0)
    err = tower_builder.connect("build_complete", self, "build_complete"); assert(err == 0)
    err = player.connect("building", tower_builder, "building"); assert(err == 0)
    err = player.connect("state_changed", tower_builder, "_on_player_state_changed"); assert(err == 0)


func build_complete():
    player.move(player.position)


func _on_player_inventory_updated(inventory):
    emit_signal("inventory_updated", inventory)
