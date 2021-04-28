;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; (--remove-unused-names avoids names on blocks, which would hamper the
;; work in getFallthrough, as a name implies possible breaks)
;; RUN: wasm-opt %s -all --remove-unused-names --ldse -S -o - | filecheck %s

(module
 (type $A (struct (field (mut i32))))
 (type $B (struct (field (mut f64))))
 (type $C (struct (field (mut i32)) (field (mut i32))))

 (memory shared 10)

 (global $global$0 (mut i32) (i32.const 0))
 (global $global$1 (mut i32) (i32.const 0))

 ;; CHECK:      (func $simple-param (param $x (ref $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $simple-param (param $x (ref $A))
  ;; a dead store using a parameter
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; another dead store
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
  ;; the last store escapes to the outside, and cannot be modified
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $simple-local
 ;; CHECK-NEXT:  (local $x (ref null $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $simple-local
  (local $x (ref null $A))
  ;; dead stores using a local
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
  ;; the last store escapes to the outside, and cannot be modified
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $simple-reaching-trap
 ;; CHECK-NEXT:  (local $x (ref null $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT: )
 (func $simple-reaching-trap
  (local $x (ref null $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; a store reaching a trap may be observable from the outside later
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
  (unreachable)
 )

 ;; CHECK:      (func $fallthrough (result (ref $A))
 ;; CHECK-NEXT:  (local $x (ref null $A))
 ;; CHECK-NEXT:  (block $func (result (ref $A))
 ;; CHECK-NEXT:   (block
 ;; CHECK-NEXT:    (drop
 ;; CHECK-NEXT:     (local.get $x)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:    (drop
 ;; CHECK-NEXT:     (i32.const 10)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (block
 ;; CHECK-NEXT:    (drop
 ;; CHECK-NEXT:     (br_on_cast $func
 ;; CHECK-NEXT:      (local.get $x)
 ;; CHECK-NEXT:      (rtt.canon $A)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:    (drop
 ;; CHECK-NEXT:     (i32.const 20)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (struct.set $A 0
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:    (i32.const 30)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (unreachable)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $fallthrough (result (ref $A))
  (local $x (ref null $A))
  (block $func (result (ref $A))
   (struct.set $A 0
    (local.get $x)
    (i32.const 10)
   )
   (struct.set $A 0
    ;; the reference can be seen to fall through this, proving the store is
    ;; dead (due to the one after it) and kills the former one.
    (br_on_cast $func
     (local.get $x)
     (rtt.canon $A)
    )
    (i32.const 20)
   )
   ;; the last store escapes to the outside, and cannot be modified
   (struct.set $A 0
    (local.get $x)
    (i32.const 30)
   )
   (unreachable)
  )
 )

 ;; CHECK:      (func $simple-fallthrough (param $x (ref $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (block (result (ref $A))
 ;; CHECK-NEXT:     (local.get $x)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (block (result (ref $A))
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $simple-fallthrough (param $x (ref $A))
  ;; simple fallthrough through a block does not confuse us, this store is dead.
  (struct.set $A 0
   (block (result (ref $A))
    (local.get $x)
   )
   (i32.const 10)
  )
  (struct.set $A 0
   (block (result (ref $A))
    (local.get $x)
   )
   (i32.const 20)
  )
 )

 ;; CHECK:      (func $get-ref (result (ref $A))
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT: )
 (func $get-ref (result (ref $A))
  (unreachable)
 )

 ;; CHECK:      (func $ref-changes (param $x (ref $A))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (local.set $x
 ;; CHECK-NEXT:   (call $get-ref)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $ref-changes (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the reference changes here, so the first store is *not* dead
  (local.set $x
   (call $get-ref)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
 )

 ;; CHECK:      (func $ref-may-change (param $x (ref $A)) (param $i i32)
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (local.get $i)
 ;; CHECK-NEXT:   (local.set $x
 ;; CHECK-NEXT:    (call $get-ref)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $ref-may-change (param $x (ref $A)) (param $i i32)
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the reference may change here
  (if
   (local.get $i)
   (local.set $x
    (call $get-ref)
   )
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
 )

 ;; CHECK:      (func $simple-use (param $x (ref $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (struct.get $A 0
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $simple-use (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 20)
  )
  ;; the second store is used by this load, and so it is not dead
  (drop
   (struct.get $A 0
    (local.get $x)
   )
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $incompatible-types (param $x (ref $A)) (param $y (ref $B))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $B 0
 ;; CHECK-NEXT:   (local.get $y)
 ;; CHECK-NEXT:   (f64.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $incompatible-types (param $x (ref $A)) (param $y (ref $B))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the second store cannot alias the first because their types differ, and
  ;; so the second store does not interfer in seeing that the first is trampled
  ;; (even though the index is identical, 0)
  (struct.set $B 0
   (local.get $y)
   (f64.const 20)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $incompatible-types-get (param $x (ref $A)) (param $y (ref $B))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (struct.get $B 0
 ;; CHECK-NEXT:    (local.get $y)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $incompatible-types-get (param $x (ref $A)) (param $y (ref $B))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the types do not allow this to alias the set before it.
  (drop
   (struct.get $B 0
    (local.get $y)
   )
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $compatible-types (param $x (ref $A)) (param $y (ref $C))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $C 0
 ;; CHECK-NEXT:   (local.get $y)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $compatible-types (param $x (ref $A)) (param $y (ref $C))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the types are compatible, so these may alias
  (struct.set $C 0
   (local.get $y)
   (i32.const 20)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $compatible-types-get (param $x (ref $A)) (param $y (ref $C))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (struct.get $C 0
 ;; CHECK-NEXT:    (local.get $y)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $compatible-types-get (param $x (ref $A)) (param $y (ref $C))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  (drop
   (struct.get $C 0
    (local.get $y)
   )
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 (func $foo)

 ;; CHECK:      (func $call (param $x (ref $A))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (call $foo)
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $call (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the analysis gives up on a call, where heap memory may be modified
  (call $foo)
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $through-branches (param $x (ref $A))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (i32.const 1)
 ;; CHECK-NEXT:   (nop)
 ;; CHECK-NEXT:   (nop)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $through-branches (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; the analysis is not confused by branching and merging; the first store is
  ;; dead
  (if (i32.const 1)
   (nop)
   (nop)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $just-one-branch-trample (param $x (ref $A))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (i32.const 1)
 ;; CHECK-NEXT:   (struct.set $A 0
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (nop)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $just-one-branch-trample (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; a trample on just one branch is not enough
  (if (i32.const 1)
   (struct.set $A 0
    (local.get $x)
    (i32.const 20)
   )
   (nop)
  )
 )

 ;; CHECK:      (func $just-one-branch-bad (param $x (ref $A))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (i32.const 1)
 ;; CHECK-NEXT:   (call $foo)
 ;; CHECK-NEXT:   (nop)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $just-one-branch-bad (param $x (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; an unknown interaction on one branch is enough to make us give up
  (if (i32.const 1)
   (call $foo)
   (nop)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $simple-in-branches (param $x (ref $A))
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (i32.const 1)
 ;; CHECK-NEXT:   (block
 ;; CHECK-NEXT:    (block
 ;; CHECK-NEXT:     (drop
 ;; CHECK-NEXT:      (local.get $x)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:     (drop
 ;; CHECK-NEXT:      (i32.const 10)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:    (struct.set $A 0
 ;; CHECK-NEXT:     (local.get $x)
 ;; CHECK-NEXT:     (i32.const 20)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (block
 ;; CHECK-NEXT:    (block
 ;; CHECK-NEXT:     (drop
 ;; CHECK-NEXT:      (local.get $x)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:     (drop
 ;; CHECK-NEXT:      (i32.const 30)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:    (struct.set $A 0
 ;; CHECK-NEXT:     (local.get $x)
 ;; CHECK-NEXT:     (i32.const 40)
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $simple-in-branches (param $x (ref $A))
  (if (i32.const 1)
   (block
    (struct.set $A 0
     (local.get $x)
     (i32.const 10)
    )
    ;; a dead store in one if arm
    (struct.set $A 0
     (local.get $x)
     (i32.const 20)
    )
   )
   (block
    (struct.set $A 0
     (local.get $x)
     (i32.const 30)
    )
    ;; another dead store in another arm
    (struct.set $A 0
     (local.get $x)
     (i32.const 40)
    )
   )
  )
 )

 ;; CHECK:      (func $different-refs-same-type (param $x (ref $A)) (param $y (ref $A))
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $y)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $A 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $different-refs-same-type (param $x (ref $A)) (param $y (ref $A))
  (struct.set $A 0
   (local.get $x)
   (i32.const 10)
  )
  ;; we do not know if x == y or not, and so must assume none of these are dead.
  (struct.set $A 0
   (local.get $y)
   (i32.const 20)
  )
  (struct.set $A 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $different-indexes (param $x (ref $C))
 ;; CHECK-NEXT:  (struct.set $C 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $C 1
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $different-indexes (param $x (ref $C))
  (struct.set $C 0
   (local.get $x)
   (i32.const 10)
  )
  ;; stores to different indexes do not interact with each other. this store is
  ;; dead because of the one after it, but the former is not dead.
  (struct.set $C 1
   (local.get $x)
   (i32.const 20)
  )
  (struct.set $C 1
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $different-pointers (param $x (ref $C)) (param $y (ref $C))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $C 1
 ;; CHECK-NEXT:   (local.get $y)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $C 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $different-pointers (param $x (ref $C)) (param $y (ref $C))
  (struct.set $C 0
   (local.get $x)
   (i32.const 10)
  )
  ;; stores to different indexes do not interact with each other, even if the
  ;; pointers are not known to be equivalent or not. this allows us to see that
  ;; the first store is trampled by the last store (both using index 0), as we
  ;; can ignore this store (to index 1)
  (struct.set $C 1
   (local.get $y)
   (i32.const 20)
  )
  (struct.set $C 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $different-pointers-get (param $x (ref $C)) (param $y (ref $C))
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (struct.get $C 1
 ;; CHECK-NEXT:    (local.get $y)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (struct.set $C 0
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $different-pointers-get (param $x (ref $C)) (param $y (ref $C))
  (struct.set $C 0
   (local.get $x)
   (i32.const 10)
  )
  ;; a load of a different index cannot interact with the first store, allowing
  ;; us to see the store is trampled (by the last store) before it has any
  ;; uses, and so it can be dropped
  (drop
   (struct.get $C 1
    (local.get $y)
   )
  )
  (struct.set $C 0
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $no-basic-blocks
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT: )
 (func $no-basic-blocks
  (unreachable)
 )

 ;; CHECK:      (func $global
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (global.set $global$1
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (global.set $global$0
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $global
  ;; globals are optimized as well, and we have more precise data there than on
  ;; GC references - aliasing is impossible, and so we can tell this first one
  ;; is dead due to the last, ignoring the unaliasing one in the middle
  (global.set $global$0
   (i32.const 10)
  )
  (global.set $global$1
   (i32.const 20)
  )
  (global.set $global$0
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $global-trap
 ;; CHECK-NEXT:  (global.set $global$0
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (if
 ;; CHECK-NEXT:   (i32.const 1)
 ;; CHECK-NEXT:   (unreachable)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (global.set $global$0
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $global-trap
  (global.set $global$0
   (i32.const 10)
  )
  ;; a trap (even conditional) prevents our optimizations, global state may be
  ;; observed if another export is called later after the trap.
  (if
   (i32.const 1)
   (unreachable)
  )
  (global.set $global$0
   (i32.const 20)
  )
 )

 ;; CHECK:      (func $memory-const
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-const
  ;; test dead store elimination of writes to memory at constant offsets
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-param (param $x i32)
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (local.get $x)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (local.get $x)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-param (param $x i32)
  ;; test dead store elimination of writes to memory using a local
  (i32.store
   (local.get $x)
   (i32.const 20)
  )
  (i32.store
   (local.get $x)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-wrong-const
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:   (i32.const 40)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-wrong-const
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store
   (i32.const 30)
   (i32.const 40)
  )
 )

 ;; CHECK:      (func $memory-wrong-offset
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store offset=1
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-wrong-offset
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store offset=1
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-wrong-size
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store16
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-wrong-size
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store16
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-other-interference
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (memory.fill
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-other-interference
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (memory.fill
   (i32.const 0)
   (i32.const 0)
   (i32.const 30)
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-load
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (i32.load
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-load
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (drop
   (i32.load
    (i32.const 10)
   )
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-load-wrong-offset
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (i32.load offset=1
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-load-wrong-offset
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  (drop
   (i32.load offset=1
    (i32.const 10)
   )
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-load-wrong-ptr
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (i32.load
 ;; CHECK-NEXT:    (i32.const 11)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-load-wrong-ptr
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  ;; this load's ptr does not match the last store's, and so the analysis
  ;; assumes they might interact
  (drop
   (i32.load
    (i32.const 11)
   )
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-load-wrong-bytes
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (i32.load8_s
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-load-wrong-bytes
  (i32.store
   (i32.const 10)
   (i32.const 20)
  )
  ;; the load's number of bytes does not match the store, so assume they
  ;; interact somehow
  (drop
   (i32.load8_s
    (i32.const 10)
   )
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-store-small
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store8
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-store-small
  ;; we can optimize dead stores of fewer bytes than the default
  (i32.store8
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store8
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-store-align
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store align=1
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-store-align
  ;; alignment is just a perf hint, and does not prevent our optimizations
  (i32.store align=2
   (i32.const 10)
   (i32.const 20)
  )
  (i32.store align=1
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; CHECK:      (func $memory-same-size-different-types
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 0)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (f32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (f32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-same-size-different-types
  ;; it doesn't matter if we are trampled by a different type; we are still
  ;; trampled, and so this store is dead.
  (i32.store
   (i32.const 10)
   (i32.const 0)
  )
  (f32.store
   (i32.const 10)
   (f32.const 0)
  )
 )

 ;; CHECK:      (func $memory-same-size-different-types-b
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i64.const 0)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (f32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (f32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-same-size-different-types-b
  (i64.store32
   (i32.const 10)
   (i64.const 0)
  )
  (f32.store
   (i32.const 10)
   (f32.const 0)
  )
 )

 ;; CHECK:      (func $memory-atomic1
 ;; CHECK-NEXT:  (i32.atomic.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-atomic1
  ;; an atomic store is not killed by a normal one (the atomic one would trap
  ;; on misalignment, for example)
  (i32.atomic.store
   (i32.const 10)
   (i32.const 0)
  )
  (i32.store
   (i32.const 10)
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $memory-atomic2
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.atomic.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-atomic2
  ;; a normal store cannot be killed by an atomic one: if the atomic store traps
  ;; then the first store's value will remain untrampled
  (i32.store
   (i32.const 10)
   (i32.const 0)
  )
  (i32.atomic.store
   (i32.const 10)
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $memory-atomic3
 ;; CHECK-NEXT:  (block
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 10)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (drop
 ;; CHECK-NEXT:    (i32.const 0)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.atomic.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-atomic3
  ;; atomic stores *can* trample each other.
  (i32.atomic.store
   (i32.const 10)
   (i32.const 0)
  )
  (i32.atomic.store
   (i32.const 10)
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $memory-unreachable
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (unreachable)
 ;; CHECK-NEXT:   (i32.const 20)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (i32.store
 ;; CHECK-NEXT:   (i32.const 10)
 ;; CHECK-NEXT:   (i32.const 30)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $memory-unreachable
  (i32.store
   (i32.const 10)
   (i32.const 10)
  )
  ;; an unreachable store does not trample
  (i32.store
   (unreachable)
   (i32.const 20)
  )
  (i32.store
   (i32.const 10)
   (i32.const 30)
  )
 )

 ;; TODO: test try throwing
)
