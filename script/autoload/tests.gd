extends Node

func _ready() -> void:
	var a: Variant
	var b: Array
	
	a = Ref.IntRW.new(15)
	b = [a, a.reader(), a.reader()]
	assert(b.all(func (x): return x.inner == a.inner))
	a.inner += 1
	assert(b.all(func (x): return x.inner == a.inner))
	
	
	a = Ref.BoolRW.new(true)
	b = [a, a.reader(), a.reader()]
	assert(b.all(func (x): return x.inner == a.inner))
	a.inner = false
	assert(b.all(func (x): return x.inner == a.inner))
	
	a = Ref.FloatRW.new(15.0)
	b = [a, a.reader(), a.reader()]
	assert(b.all(func (x): return x.inner == a.inner))
	a.inner += 1.0
	assert(b.all(func (x): return x.inner == a.inner))
	
	
	
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
