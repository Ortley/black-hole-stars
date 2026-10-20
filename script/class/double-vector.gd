extends Object
class_name DoubleVector

var x: float
var y: float
var z: float

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
