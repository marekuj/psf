extends Node

var position
var velocity          = Vector3( 0.0, 0.0, 0.0 )
var previous_position = Vector3( 0.0, 0.0, 0.0 )
var gravity           = Vector3( 0.0, 0.0, 0.0 )
var viscosity         = Vector3( 0.0, 0.0, 0.0 )
var zero_tolerance    = 0.00001

var mass      = 1.0
var mu        = 1.0 # 1./mass

var node_mass = 0
var node_body = 0

var is_static = false
onready var point = $"point"
onready var arrow = $"point/arrow"
onready var arrowhead  = $"point/arrowhead"
var up = Vector3(0.0,1.0,0.0)
var right = Vector3(1.0,0.0,0.0)

func _ready():
	# setting velocity
	velocity = 0.01*Vector3(2*randf()-1.0,randf(),2*randf()-1.0)
	
	# setting positions
	previous_position = position - velocity * get_physics_process_delta_time()
	point.global_translate(position)
	
	# setting color
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(randf(),randf(),randf())
	mat.set_metallic(0.0)
	mat.set_specular(0.0)
	point.set_surface_material(0,mat)
	arrow.set_surface_material(0,mat)
	arrowhead.set_surface_material(0,mat)

var iter = 0

func _physics_process(delta):
	if !is_static:
		verlet(delta)
		collision_sphere(delta, node_mass)
		collision_sphere(delta, node_body)

func _process(delta):
	if !is_static:
		point.translation = position
		arrow.scale = Vector3(0.2,10.0*velocity.length(),0.2)
		arrow.translation = Vector3(0.0,10.0*velocity.length(),0.0)
		arrowhead.translation = Vector3(0.0,20.0*velocity.length(),0.0)
		var axis = up.cross(velocity.normalized())
		var angle = acos(up.dot(velocity.normalized()))
		if axis.length() > 1e-3:
			point.global_rotate(axis.normalized(),angle)
		up = velocity.normalized()

func set_velocity(v):
	velocity          = v
	previous_position = position - velocity * get_physics_process_delta_time()

func set_mass(m):
	mass = m
	mu   = pow( m, -1.0 )

func collision_sphere(delta, node):
	var dist = position - node.position
	if dist.length() < radius() + node.radius + 0.1:
		var n = dist.normalized()
		var v_r = velocity.dot(n) * n
		var v_p = velocity - v_r;
		velocity = v_p - v_r
		var F = force(delta)
		var F_r = F.dot(n) * n
		var R = -F_r 
		var T = -0.5 * F_r * v_p.normalized()
		euler(delta, F + R + T)

func euler(delta,f=force(delta)):
	velocity += f * mu * delta
	previous_position = position
	position += velocity * delta

func verlet(delta, f=force(delta)):
	var new_position  = 2 * position - previous_position + f * mu * pow( delta , 2.0 )
	previous_position = position
	position          = new_position
	velocity          = ( position - previous_position ) / delta
	
func force(delta):
	var distance = position - node_mass.position
	gravity = Vector3(0,0,0)
	if distance.length() > 0.01:
		gravity = -self.mass * distance * pow(distance.length(), -3)
		viscosity = -0.4*self.velocity
#	if distance.length() > 10:
#		if distance.dot(velocity) > 0:
#			viscosity *= 2
#		else:
#			gravity *= 10
	return gravity + viscosity

func radius():
	return self.get_physics_process_delta_time()*self.velocity.length() + zero_tolerance
