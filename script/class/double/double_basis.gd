extends RefCounted
class_name DoubleBasis

var x: DoubleVector
var y: DoubleVector
var z: DoubleVector

@warning_ignore("shadowed_variable")
func _init(x: DoubleVector, y: DoubleVector, z: DoubleVector) -> void:
	self.x = x
	self.y = y
	self.z = z

static func IDENTITY() -> DoubleBasis:
	return DoubleBasis.new(	DoubleVector.new(1.0, 0.0, 0.0),
							DoubleVector.new(0.0, 1.0, 0.0),
							DoubleVector.new(0.0, 0.0, 1.0))


func duplicate() -> DoubleBasis:
	return DoubleBasis.new(x.duplicate(), y.duplicate(), z.duplicate())


static func from_basis(b: Basis) -> DoubleBasis:
	return DoubleBasis.new(DoubleVector.from_vec3(b.x), DoubleVector.from_vec3(b.y), DoubleVector.from_vec3(b.z))

func to_basis() -> Basis:
	return Basis(x.to_vec3(), y.to_vec3(), z.to_vec3())


func mul(rhs: DoubleBasis) -> DoubleBasis:
	return DoubleBasis.new(
		DoubleVector.new(	x.x * rhs.x.x + y.x * rhs.x.y + z.x * rhs.x.z, 
							x.y * rhs.x.x + y.y * rhs.x.y + z.y * rhs.x.z, 
							x.z * rhs.x.x + y.z * rhs.x.y + z.z * rhs.x.z), 
		DoubleVector.new(	x.x * rhs.y.x + y.x * rhs.y.y + z.x * rhs.y.z, 
							x.y * rhs.y.x + y.y * rhs.y.y + z.y * rhs.y.z, 
							x.z * rhs.y.x + y.z * rhs.y.y + z.z * rhs.y.z), 
		DoubleVector.new(	x.x * rhs.z.x + y.x * rhs.z.y + z.x * rhs.z.z, 
							x.y * rhs.z.x + y.y * rhs.z.y + z.y * rhs.z.z, 
							x.z * rhs.z.x + y.z * rhs.z.y + z.z * rhs.z.z))


func snappedf(step: float) -> DoubleBasis:
	return DoubleBasis.new(x.snappedf(step), y.snappedf(step), z.snappedf(step))

func _to_string() -> String:
	return "[x: %s, Y: %s, Z: %s]" % [x, y, z]
