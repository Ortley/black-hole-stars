extends RefCounted
class_name DoubleVector

var x: float
var y: float
var z: float

@warning_ignore("shadowed_variable")
func _init(x: float = 0, y: float = 0, z: float = 0) -> void:
	self.x = x;
	self.y = y;
	self.z = z;

func add(rhs: DoubleVector) -> DoubleVector:
	return DoubleVector.new(
			self.x + rhs.x, 
			self.y + rhs.y,
			self.z + rhs.z
		)

func sub(rhs: DoubleVector) -> DoubleVector:
	return DoubleVector.new(
			self.x - rhs.x, 
			self.y - rhs.y,
			self.z - rhs.z
		)

static func from_vec3(v: Vector3) -> DoubleVector:
	return DoubleVector.new(v.x, v.y, v.z)

func duplicate() -> DoubleVector:
	return DoubleVector.new(x, y, z)

func write_into(from: DoubleVector):
	x = from.x
	y = from.y
	z = from.z

func vec3() -> Vector3:
	return Vector3(x, y, z)

func length() -> float:
	return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

func length_squared() -> float:
	return self.x * self.x + self.y * self.y + self.z * self.z

func distance(to: DoubleVector) -> float:
	var diff = DoubleVector.new(to.x - self.x, to.y - self.y, to.z - self.z)
	return diff.length()

func distance_squared(to: DoubleVector) -> float:
	var diff = DoubleVector.new(to.x - self.x, to.y - self.y, to.z - self.z)
	return diff.length_squared()
