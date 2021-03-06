// RUN: %target-swift-frontend -O -emit-sil %s | FileCheck %s
// We want to check two things here:
// - Correctness
// - That certain "is" checks are eliminated based on static analysis at compile-time
//
// In ideal world, all those testNN functions should be simplified down to a single basic block
// which returns either true or false, i.e. all type checks should folded statically.

// REQUIRES: objc_interop

import Foundation

class ObjCX : NSObject {}

struct CX: _ObjectiveCBridgeable {
  static func _isBridgedToObjectiveC() -> Bool {
    return true
  }

  func _bridgeToObjectiveC() -> ObjCX {
    return ObjCX()
  }

  static func _forceBridgeFromObjectiveC(_ source: ObjCX, result: inout CX?) {}

  static func _conditionallyBridgeFromObjectiveC(_ source: ObjCX, result: inout CX?) -> Bool {
    return false
  }

  static func _unconditionallyBridgeFromObjectiveC(_ source: ObjCX?)
      -> CX {
    var result: CX? = nil
    _forceBridgeFromObjectiveC(source!, result: &result)
    return result!
  }
}

// Check casts to types which are _ObjectiveCBridgeable
func cast0(_ o: AnyObject) -> Bool {
  return o is CX
}

// CHECK-LABEL: sil hidden [noinline] @_TF17cast_folding_objc5test0FT_Sb
// CHECK: bb0
// Check that cast is not eliminated even though cast0 is a conversion
// from a class to struct, because it casts to a struct implementing
// the _BridgedToObjectiveC protocol
// CHECK: checked_cast
// CHECK: return
@inline(never)
func test0() -> Bool {
  return cast0(NSNumber(value:1))
}

// Check that this cast does not get eliminated, because
// the compiler does not statically know if this object
// is NSNumber can be converted into Int.
@inline(never)
public func testMayBeBridgedCastFromObjCtoSwift(_ o: AnyObject) -> Int {
  return o as! Int
}

// Check that this cast does not get eliminated, because
// the compiler does not statically know if this object
// is NSString can be converted into String.
@inline(never)
public func testConditionalBridgedCastFromObjCtoSwift(_ o: AnyObject) -> String? {
  return o as? String
}

public func castObjCToSwift<T>(_ t: T) -> Int {
  return t as! Int
}

// Check that compiler understands that this cast always fails
// CHECK-LABEL: sil [noinline] @_TF17cast_folding_objc37testFailingBridgedCastFromObjCtoSwiftFCSo8NSStringSi
// CHECK: builtin "int_trap"
// CHECK-NEXT: unreachable
// CHECK-NEXT: }
@inline(never)
public func testFailingBridgedCastFromObjCtoSwift(_ ns: NSString) -> Int {
  return castObjCToSwift(ns)
}

// Check that compiler understands that this cast always fails
// CHECK-LABEL: sil [noinline] @_TF17cast_folding_objc37testFailingBridgedCastFromSwiftToObjCFSSSi
// CHECK: builtin "int_trap"
// CHECK-NEXT: unreachable
// CHECK-NEXT: }
@inline(never)
public func testFailingBridgedCastFromSwiftToObjC(_ s: String) -> NSInteger {
  return s as! NSInteger
}

@inline(never)
public func testCastNSObjectToAnyClass(_ o: NSObject) -> AnyClass {
  return o as! AnyClass
}

@inline(never)
public func testCastNSObjectToClassObject(_ o: NSObject) -> NSObject.Type {
  return o as! NSObject.Type
}

@inline(never)
public func testCastNSObjectToAnyType(_ o: NSObject) -> Any.Type {
  return o as! Any.Type
}

@inline(never)
public func testCastNSObjectToEveryType<T>(_ o: NSObject) -> T.Type {
  return o as! T.Type
}

@inline(never)
public func testCastNSObjectToNonClassType(_ o: NSObject) -> Int.Type {
  return o as! Int.Type
}

@inline(never)
public func testCastAnyObjectToAnyClass(_ o: AnyObject) -> AnyClass {
  return o as! AnyClass
}

@inline(never)
public func testCastAnyObjectToClassObject(_ o: AnyObject) -> AnyObject.Type {
  return o as! AnyObject.Type
}

@inline(never)
public func testCastAnyObjectToAnyType(_ o: AnyObject) -> Any.Type {
  return o as! Any.Type
}

@inline(never)
public func testCastAnyObjectToEveryType<T>(_ o: AnyObject) -> T.Type {
  return o as! T.Type
}

@inline(never)
public func testCastAnyObjectToNonClassType(_ o: AnyObject) -> Int.Type {
  return o as! Int.Type
}

@inline(never)
public func testCastAnyToAnyClass(_ o: Any) -> AnyClass {
  return o as! AnyClass
}

@inline(never)
public func testCastAnyToClassObject(_ o: Any) -> AnyObject.Type {
  return o as! AnyObject.Type
}

@inline(never)
public func testCastAnyToAnyType(_ o: Any) -> Any.Type {
  return o as! Any.Type
}

@inline(never)
public func testCastAnyToEveryType<T>(_ o: Any) -> T.Type {
  return o as! T.Type
}

@inline(never)
public func testCastAnyToNonClassType(_ o: Any) -> Int.Type {
  return o as! Int.Type
}

@inline(never)
public func testCastEveryToAnyClass<T>(_ o: T) -> AnyClass {
  return o as! AnyClass
}

@inline(never)
public func testCastEveryToClassObject<T>(_ o: T) -> AnyObject.Type {
  return o as! AnyObject.Type
}

@inline(never)
public func testCastEveryToAnyType<T>(_ o: T) -> Any.Type {
  return o as! Any.Type
}

@inline(never)
public func testCastEveryToEveryType<T, U>(_ o: U) -> T.Type {
  return o as! T.Type
}

@inline(never)
public func testCastEveryToNonClassType<T>(_ o: T) -> Int.Type {
  return o as! Int.Type
}

print("test0=\(test0())")


// CHECK-LABEL: sil [noinline] @{{.*}}testCastNSObjectToEveryType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastNSObjectToNonClassType
// CHECK:         builtin "int_trap"

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyObjectToEveryType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyObjectToNonClassType
// CHECK:         builtin "int_trap"

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyToAnyClass{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyToClassObject{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyToAnyType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyToEveryType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastAnyToNonClassType
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastEveryToAnyClass{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastEveryToClassObject{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastEveryToAnyType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastEveryToEveryType{{.*}}
// CHECK:         unconditional_checked_cast_addr

// CHECK-LABEL: sil [noinline] @{{.*}}testCastEveryToNonClassType
// CHECK:         unconditional_checked_cast_addr



// Check that compiler understands that this cast always succeeds.
// Since it is can be statically proven that NSString is bridgeable to String,
// _forceBridgeFromObjectiveC from String should be invoked instead of
// a more general, but less effective swift_bridgeNonVerbatimFromObjectiveC, which
// also performs conformance checks at runtime.
@inline(never)
public func testBridgedCastFromObjCtoSwift(_ ns: NSString) -> String {
  return ns as String
}

// Check that compiler understands that this cast always succeeds
@inline(never)
public func testBridgedCastFromSwiftToObjC(_ s: String) -> NSString {
  return s as NSString
}

// CHECK-LABEL: sil [noinline] @_TTSf4g___TF17cast_folding_objc35testMayBeBridgedCastFromObjCtoSwiftFPs9AnyObject_Si
// CHECK: unconditional_checked_cast_addr
// CHECK: return

// CHECK-LABEL: sil [noinline] @_TTSf4g___TF17cast_folding_objc41testConditionalBridgedCastFromObjCtoSwiftFPs9AnyObject_GSqSS_
// CHECK: unconditional_checked_cast_addr
// CHECK: return

// CHECK-LABEL: sil [noinline] @_TTSf4gs___TF17cast_folding_objc30testBridgedCastFromSwiftToObjCFSSCSo8NSString
// CHECK-NOT: {{ cast}}
// CHECK: function_ref @_TFE10FoundationSS19_bridgeToObjectiveC
// CHECK: apply
// CHECK: return
