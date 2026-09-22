extends Node3D
## Physical, original low-poly Egyptian night block. Every solid obstacle has a 3D collider.
## Decorative art is explicitly not collidable. All geometry is authored at mobile budgets.
const WALL := Color("c4ac99")
const PLASTER := Color("9e8f9a")
const INDIGO := Color("403c63")
const GOLD := Color("f9c878")
var doors: Dictionary = {}
var points: Dictionary = {}
var clues: Dictionary = {}

func build(case_data: Dictionary) -> void:
	_solid(Vector3(0, -0.36, -2), Vector3(27, 0.7, 31), Color("383a50"), "ground")
	_solid(Vector3(0, -0.005, 7), Vector3(25, 0.015, 7), Color("4b4555"), "street")
	for i in range(-10, 11, 4):
		_mesh(Vector3(float(i), 0.017, 7), Vector3(1.6, 0.018, 0.11), GOLD)
	_solid(Vector3(-12.9, 1.65, -2), Vector3(0.28, 3.3, 28), PLASTER, "outer_west")
	_solid(Vector3(12.9, 1.65, -2), Vector3(0.28, 3.3, 28), PLASTER, "outer_east")
	_solid(Vector3(0, 1.65, -14.5), Vector3(26, 3.3, 0.26), PLASTER, "outer_north")
	_solid(Vector3(0, 0.8, 11.6), Vector3(26, 1.6, 0.22), Color("51475a"), "street_edge")
	for id in case_data.get("map", {}):
		var location: Dictionary = case_data["map"][id]
		points[id] = Vector3(float(location["x"]), 0.0, float(location["z"]))
	_room("office", Color("706078"))
	_room("maintenance", Color("57727b"))
	_room("roof", Color("81728b"))
	_room("shop", Color("877355"))
	_build_entrance()
	_build_stairs()
	_build_furniture()
	_build_street()
	_build_witness()
	clues = {
		"camera_frame":Vector3(0,0,-0.4),
		"clock_note":Vector3(-8.2,0,-0.7),
		"glass":Vector3(-5.9,0,-3.6),
		"power_log":Vector3(6.2,0,-0.7),
		"ups":Vector3(8.0,0,-3.5),
		"witness_coat":Vector3(1.45,0,7.0),
		"roof_marks":Vector3(-7.0,0,-11.0),
		"shop_receipt":Vector3(7.0,0,-11.0)
	}
	for id in clues:
		var point: Vector3 = clues[id]
		_mesh(point + Vector3(0,0.055,0), Vector3(0.42,0.06,0.42), GOLD)

func _room(id: String, tint: Color) -> void:
	var p: Vector3 = points[id]
	_mesh(p + Vector3(0,0.018,0), Vector3(5.7,0.045,5.7),tint)
	var left := id in ["office","roof"]
	var inner_x := p.x + (2.84 if left else -2.84)
	var outer_x := p.x + (-2.84 if left else 2.84)
	_solid(Vector3(outer_x,1.45,p.z),Vector3(0.20,2.9,5.9),WALL,id+"_outer")
	for sign_z in [-1.0,1.0]:
		_solid(Vector3(inner_x,1.45,p.z + sign_z*1.96),Vector3(0.23,2.9,1.97),WALL,id+"_inner")
	_solid(Vector3(p.x,1.45,p.z - 2.84),Vector3(5.9,2.9,0.22),WALL,id+"_back")
	_solid(Vector3(p.x,1.45,p.z + 2.84),Vector3(5.9,2.9,0.22),WALL,id+"_front")
	_mesh(Vector3(p.x,3.12,p.z),Vector3(5.9,0.19,5.9),Color("483e50"))
	_mesh(Vector3(p.x,3.17,p.z),Vector3(6.35,0.09,6.35),INDIGO)
	_door(id,Vector3(inner_x,0,p.z))
	for zsign in [-1.0,1.0]:
		_mesh(Vector3(outer_x + (-0.14 if left else 0.14),1.73,p.z+zsign*1.1),
			Vector3(0.08,0.8,0.75),Color("f8cb80"))
		_mesh(Vector3(outer_x + (-0.20 if left else 0.20),1.73,p.z+zsign*1.1),
			Vector3(0.035,0.72,0.05),INDIGO)

func _door(id: String, center: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = id + "_door"
	body.position = center
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.20,2.35,1.54)
	collision.shape = shape
	collision.position.y = 1.175
	body.add_child(collision)
	var pivot := Node3D.new()
	body.add_child(pivot)
	var panel := _mesh(Vector3(0,1.14,0),Vector3(0.17,2.28,1.5),Color("6c4f4d"),pivot)
	panel.position.z = -0.73
	pivot.position.z = 0.73
	_mesh(Vector3(0.14,1.1,0.3),Vector3(0.07,0.12,0.12),GOLD,pivot)
	doors[id] = {"body":body,"shape":collision,"pivot":pivot,"open":false}

func nearest_door(position: Vector3, distance: float = 2.3) -> String:
	var chosen := ""
	for id in doors:
		var d: float = position.distance_to(doors[id]["body"].global_position)
		if d < distance:
			distance = d
			chosen = id
	return chosen

func toggle_door(id: String, position: Vector3) -> bool:
	if not doors.has(id) or position.distance_to(doors[id]["body"].global_position) > 2.3:
		return false
	var door: Dictionary = doors[id]
	door["open"] = not door["open"]
	var col: CollisionShape3D = door["shape"]
	col.set_deferred("disabled", door["open"])
	var pivot: Node3D = door["pivot"]
	var tween := create_tween()
	tween.tween_property(pivot,"rotation:y", -1.48 if door["open"] else 0.0,0.24)
	return true

func _build_entrance() -> void:
	for x in [-2.65,2.65]:
		_solid(Vector3(x,1.52,-0.3),Vector3(0.36,3.04,0.36),WALL,"portico")
	_mesh(Vector3(0,3.03,-0.3),Vector3(5.9,0.35,1.05),Color("665a71"))
	_mesh(Vector3(0,2.78,-0.9),Vector3(1.6,0.18,0.1),GOLD)
	_mesh(Vector3(0,1.4,-0.4),Vector3(1.75,1.1,0.16),Color("242b3b"))
	_mesh(Vector3(0,1.4,-0.51),Vector3(1.33,0.82,0.10),Color("92c0bd"))
	for x in [-1.3,1.3]:
		_solid(Vector3(x,0.65,-1.4),Vector3(0.45,1.3,0.45),Color("79636b"),"planter")
		_mesh(Vector3(x,1.35,-1.4),Vector3(0.64,0.15,0.64),Color("6f967b"))

func _build_stairs() -> void:
	for i in range(4):
		_solid(Vector3(0,0.10+float(i)*0.05,-6.25-float(i)*0.39),
			Vector3(2.15,0.20+float(i)*0.1,0.36),Color("a29993"),"stair_step")

func _build_furniture() -> void:
	_solid(Vector3(-7,0.48,-2),Vector3(2.3,0.96,1.2),Color("6f5148"),"office_desk")
	_mesh(Vector3(-7,0.99,-2),Vector3(2.5,0.11,1.38),Color("d4b398"))
	_solid(Vector3(-8.6,0.45,-3.6),Vector3(0.48,0.9,0.48),Color("4d4964"),"chair")
	_solid(Vector3(7,0.98,-2),Vector3(1.6,1.95,0.48),Color("5e7a7a"),"fuse_cabinet")
	for index in range(3):
		_mesh(Vector3(6.45+float(index)*0.5,1.37,-2.26),Vector3(0.14,0.34,0.05),GOLD)
	_solid(Vector3(8.35,0.32,-3.45),Vector3(0.63,0.64,0.64),Color("42485d"),"ups_unit")
	for index in range(3):
		_solid(Vector3(6.0+float(index),0.48,-10.75),Vector3(0.78,0.96,1.3),
			Color("9f8658"),"shop_shelf")
	_solid(Vector3(-7,0.3,-11.9),Vector3(2.0,0.6,0.6),Color("76788a"),"roof_vent")
	_solid(Vector3(9,0.23,-9.8),Vector3(0.6,0.46,0.6),Color("7d6d62"),"crate")
	# Evidence-card pedestals get individual props without collision so they stay reachable.
	_mesh(Vector3(-8.2,1.06,-0.7),Vector3(0.44,0.035,0.32),Color("eee4c5"))
	_mesh(Vector3(6.2,1.25,-0.7),Vector3(0.48,0.035,0.34),Color("eee4c5"))

func _build_street() -> void:
	for x in [-10.1,10.1]:
		_light_pole(Vector3(x,0,6.2))
	for x in [-10.6,10.6]:
		_tree(Vector3(x,0,3.5))
	for x in [-10.8,10.8]:
		for z in [-11.3,-7.0,-2.1]:
			_mesh(Vector3(x,2.3,z),Vector3(0.07,0.95,1.2),Color("f5c784"))
			_mesh(Vector3(x,3.13,z),Vector3(0.08,0.13,1.25),Color("564b72"))
	for x in [-11.0,11.0]:
		_mesh(Vector3(x,3.25,1.8),Vector3(2.7,0.22,1.4),Color("574263"))
	_solid(Vector3(-10.5,0.36,8.8),Vector3(1.7,0.72,0.65),Color("736273"),"bench")
	_solid(Vector3(10.2,0.30,8.8),Vector3(0.65,0.6,0.62),Color("6c7784"),"bin")

func _light_pole(origin: Vector3) -> void:
	_solid(origin+Vector3(0,2.15,0),Vector3(0.19,4.3,0.19),Color("31344c"),"lamp_post")
	_mesh(origin+Vector3(0.48,4.31,0),Vector3(0.95,0.11,0.13),Color("31344c"))
	_mesh(origin+Vector3(0.9,4.20,0),Vector3(0.38,0.15,0.28),GOLD)

func _tree(origin: Vector3) -> void:
	_solid(origin+Vector3(0,0.62,0),Vector3(0.35,1.24,0.35),Color("715048"),"tree_trunk")
	var foliage := SphereMesh.new()
	foliage.radius = 1.05
	foliage.height = 1.6
	foliage.radial_segments = 7
	foliage.rings = 4
	var crown := MeshInstance3D.new()
	crown.mesh = foliage
	crown.position = origin+Vector3(0,2.12,0)
	crown.material_override = _material(Color("53746c"))
	add_child(crown)

func _build_witness() -> void:
	var npc := StaticBody3D.new()
	npc.name = "Amina"
	npc.position = Vector3(1.45,0,7)
	add_child(npc)
	var shape := CapsuleShape3D.new()
	shape.height = 1.64
	shape.radius = 0.34
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.85
	npc.add_child(collision)
	_mesh(Vector3(0,0.86,0),Vector3(0.72,1.05,0.52),Color("b86962"),npc)
	_mesh(Vector3(0,1.54,0),Vector3(0.48,0.47,0.45),Color("edb58e"),npc)
	_mesh(Vector3(0,1.81,0),Vector3(0.68,0.18,0.53),Color("353047"),npc)
	for x in [-0.20,0.20]:
		_mesh(Vector3(x,0.23,0),Vector3(0.18,0.45,0.24),Color("39334b"),npc)
		_mesh(Vector3(x,1.58,-0.236),Vector3(0.055,0.045,0.025),Color("2d2736"),npc)

func _solid(pos: Vector3, dimensions: Vector3, tint: Color, kind: String) -> StaticBody3D:
	var solid := StaticBody3D.new()
	solid.name = kind
	solid.position = pos
	add_child(solid)
	_mesh(Vector3.ZERO,dimensions,tint,solid)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	solid.add_child(collider)
	return solid

func _mesh(pos: Vector3, dimensions: Vector3, tint: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = _material(tint)
	(parent if parent != null else self).add_child(mesh)
	return mesh

func _material(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.95
	return m
