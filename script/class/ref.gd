extends RefCounted
class_name Ref

const WRITE_ON_READ := "%s is read-only!!!!! don't even TRY writing to it !!!"

class VarRW:
	var inner: Variant
	
	func _init(value: Variant = null) -> void:
		inner = value
	
	func reader() -> VarR:
		return VarR.new(self)

class VarR:
	var _source: VarRW
	var inner: Variant:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "VarR")
	
	func _init(source: VarRW) -> void:
		_source = source


class IntRW:
	var inner: int
	
	func _init(value: int = 0) -> void:
		inner = value
	
	func reader() -> IntR:
		return IntR.new(self)

class IntR:
	var _source: IntRW
	var inner: int:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "IntR")
	
	func _init(source: IntRW) -> void:
		_source = source


class BoolRW:
	var inner: bool
	
	func _init(value: bool = false) -> void:
		inner = value
	
	func reader() -> BoolR:
		return BoolR.new(self)

class BoolR:
	var _source: BoolRW
	var inner: bool:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "BoolR")
	
	func _init(source: BoolRW) -> void:
		_source = source




class FloatRW:
	var inner: float
	
	func _init(value: float = 0.0) -> void:
		inner = value
	
	func reader() -> FloatR:
		return FloatR.new(self)

class FloatR:
	var _source: FloatRW
	var inner: float:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "FloatR")
	
	func _init(source: FloatRW) -> void:
		_source = source


class BasisRW:
	var inner: Basis
	
	func _init(value: Basis = Basis.IDENTITY) -> void:
		inner = value
	
	func reader() -> BasisR:
		return BasisR.new(self)

class BasisR:
	var _source: BasisRW
	var inner: Basis:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "BasisR")
	
	func _init(source: BasisRW) -> void:
		_source = source


class QuaternionRW:
	var inner: Quaternion
	
	func _init(value: Quaternion = Quaternion.IDENTITY) -> void:
		inner = value
	
	func reader() -> QuaternionR:
		return QuaternionR.new(self)

class QuaternionR:
	var _source: QuaternionRW
	var inner: Quaternion:
		get(): return _source.inner
		set(_v): assert(false, WRITE_ON_READ % "QuaternionR")
	
	func _init(source: QuaternionRW) -> void:
		_source = source
