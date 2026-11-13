extends Node

func _ready() -> void:
	var x := Ref.Bool.new(true)
	var y := x
	assert(y.value == true)
	x.value = false
	assert(y.value == false)
	
	var p := Ref.Int.new(123)
	var q := p
	
	assert(p.value == q.value)
	p.value += 10
	assert(p.value == q.value)
	q.value -= 100
	assert(p.value == q.value)
	q.value *= 10
	assert(p.value == q.value)
	
	print("RAN TESTS!")
	

#func test() -> void:
	#var B: Array = (range(0, 100)
		#.map(func (x): return deg_to_rad(x))
		#.map(func (x): return Basis.IDENTITY.rotated(Vector3.UP, x).rotated(Vector3(3, 5, 1).normalized(), 2.0 * x)))
	#var DB: Array = (B
		#.map(func (x): return DoubleBasis.from_basis(x)))
	#
	#
	#for i in range(0, 100, 10):
		#for j in range(0, 100, 10):
			#var result: bool = str(B[i] * B[j]) == str(DB[i].mul(DB[j]))
			#print(result)
			#if result == false:
				#print("------")
				#print(B[i] * B[j])
				#print(DB[i].mul(DB[j]))
