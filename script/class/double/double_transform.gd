extends RefCounted
class_name DoubleTransform

var basis: DoubleBasis = DoubleBasis.IDENTITY()
var origin: DoubleVector = DoubleVector.new()

func translated(offset: DoubleVector) -> DoubleTransform:
	var out := DoubleTransform.new()
	out.basis = basis.duplicate()
	out.origin = origin.add(offset)
	return out


static func from_transform(t: Transform3D) -> DoubleTransform:
	var out := DoubleTransform.new()
	out.basis = DoubleBasis.from_basis(t.basis)
	out.origin = DoubleVector.from_vec3(t.origin)
	return out

func snappedf(step: float) -> DoubleTransform:
	var out := DoubleTransform.new()
	out.basis = basis.snappedf(step)
	out.origin = origin.snappedf(step)
	return out
