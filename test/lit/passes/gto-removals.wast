;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt --nominal --gto -all -S -o - | filecheck %s
;; (remove-unused-names is added to test fallthrough values without a block
;; name getting in the way)

(module
  ;; A struct with a field that is never read or written, so it can be
  ;; removed.

  ;; CHECK:      (type $ref|$struct|_=>_none (func (param (ref $struct))))

  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct (field (mut funcref))))

  ;; CHECK:      (func $func (param $x (ref $struct))
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func (param $x (ref $struct))
  )
)

(module
  ;; A write does not keep a field from being removed.

  ;; CHECK:      (type $ref|$struct|_=>_none (func (param (ref $struct))))

  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct (field (mut funcref))))

  ;; CHECK:      (func $func (param $x (ref $struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.null func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func (param $x (ref $struct))
    ;; The fields of this set will be dropped, as we do not need to perform
    ;; the write.
    (struct.set $struct 0
      (local.get $x)
      (ref.null func)
    )
  )
)

(module
  ;; A new does not keep a field from being removed.

  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct (field (mut funcref))))

  ;; CHECK:      (type $ref|$struct|_=>_none (func (param (ref $struct))))

  ;; CHECK:      (func $func (param $x (ref $struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func (param $x (ref $struct))
    ;; The fields in this new will be removed.
    (drop
      (struct.new $struct
        (ref.null func)
      )
    )
  )
)

(module
  ;; A new_default does not keep a field from being removed.

  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct (field (mut funcref))))

  ;; CHECK:      (type $ref|$struct|_=>_none (func (param (ref $struct))))

  ;; CHECK:      (func $func (param $x (ref $struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func (param $x (ref $struct))
    ;; The fields in this new will be removed.
    (drop
      (struct.new_default $struct
      )
    )
  )
)

(module
  ;; A read *does* keep a field from being removed.

  ;; CHECK:      (type $struct (struct (field funcref)))
  (type $struct (struct (field (mut funcref))))

  ;; CHECK:      (type $ref|$struct|_=>_none (func (param (ref $struct))))

  ;; CHECK:      (func $func (param $x (ref $struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func (param $x (ref $struct))
    (drop
      (struct.get $struct 0
        (local.get $x)
      )
    )
  )
)

(module
  ;; Different struct types with different situations: some fields are read,
  ;; some written, and some both. (Note that this also tests the interaction
  ;; of removing with the immutability inference that --gto does.)

  ;; A struct with all fields marked mutable.
  ;; CHECK:      (type $mut-struct (struct (field $r i32) (field $rw (mut i32)) (field $r-2 i32) (field $rw-2 (mut i32))))
  (type $mut-struct (struct (field $r (mut i32)) (field $w (mut i32)) (field $rw (mut i32)) (field $r-2 (mut i32)) (field $w-2 (mut i32)) (field $rw-2 (mut i32))))

  ;; A similar struct but with all fields marked immutable, and the only
  ;; writes are from during creation (so all fields are at least writeable).
  ;; CHECK:      (type $imm-struct (struct (field $rw i32) (field $rw-2 i32)))
  (type $imm-struct (struct (field $w i32) (field $rw i32) (field $w-2 i32) (field $rw-2 i32)))

  ;; CHECK:      (type $ref|$mut-struct|_=>_none (func (param (ref $mut-struct))))

  ;; CHECK:      (type $ref|$imm-struct|_=>_none (func (param (ref $imm-struct))))

  ;; CHECK:      (func $func-mut (param $x (ref $mut-struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $mut-struct $r
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (struct.set $mut-struct $rw
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $mut-struct $rw
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $mut-struct $r-2
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (struct.set $mut-struct $rw-2
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (i32.const 3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $mut-struct $rw-2
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func-mut (param $x (ref $mut-struct))
    ;; $r is only read
    (drop
      (struct.get $mut-struct $r
        (local.get $x)
      )
    )
    ;; $w is only written
    (struct.set $mut-struct $w
      (local.get $x)
      (i32.const 0)
    )
    ;; $rw is both
    (struct.set $mut-struct $rw
      (local.get $x)
      (i32.const 1)
    )
    (drop
      (struct.get $mut-struct $rw
        (local.get $x)
      )
    )
    ;; The same, for the $*-2 fields
    (drop
      (struct.get $mut-struct $r-2
        (local.get $x)
      )
    )
    (struct.set $mut-struct $w-2
      (local.get $x)
      (i32.const 2)
    )
    (struct.set $mut-struct $rw-2
      (local.get $x)
      (i32.const 3)
    )
    (drop
      (struct.get $mut-struct $rw-2
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $func-imm (param $x (ref $imm-struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $imm-struct
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $imm-struct $rw
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $imm-struct $rw-2
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func-imm (param $x (ref $imm-struct))
    ;; create an instance
    (drop
      (struct.new $imm-struct
        (i32.const 0)
        (i32.const 1)
        (i32.const 2)
        (i32.const 3)
      )
    )
    ;; $rw and $rw-2 are also read
    (drop
      (struct.get $imm-struct $rw
        (local.get $x)
      )
    )
    (drop
      (struct.get $imm-struct $rw-2
        (local.get $x)
      )
    )
  )
)

(module
  ;; A vtable-like structure created in a global location. Only some of the
  ;; fields are accessed.

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $vtable (struct (field $v1 funcref) (field $v2 funcref)))
  (type $vtable (struct (field $v0 funcref) (field $v1 funcref) (field $v2 funcref) (field $v3 funcref) (field $v4 funcref)))

  ;; CHECK:      (global $vtable (ref $vtable) (struct.new $vtable
  ;; CHECK-NEXT:  (ref.func $func-1)
  ;; CHECK-NEXT:  (ref.func $func-2)
  ;; CHECK-NEXT: ))
  (global $vtable (ref $vtable) (struct.new $vtable
    (ref.func $func-0)
    (ref.func $func-1)
    (ref.func $func-2)
    (ref.func $func-3)
    (ref.func $func-4)
  ))

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $vtable $v1
  ;; CHECK-NEXT:    (global.get $vtable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $vtable $v2
  ;; CHECK-NEXT:    (global.get $vtable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    ;; To differ from previous tests, do not read the very first field.
    (drop
      (struct.get $vtable 1
        (global.get $vtable)
      )
    )
    ;; To differ from previous tests, do reads in two adjacent fields.
    (drop
      (struct.get $vtable 2
        (global.get $vtable)
      )
    )
    ;; To differ from previous tests, do not read the very last field, and the
    ;; one before it.
  )

  ;; CHECK:      (func $func-0
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func-0)
  ;; CHECK:      (func $func-1
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func-1)
  ;; CHECK:      (func $func-2
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func-2)
  ;; CHECK:      (func $func-3
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func-3)
  ;; CHECK:      (func $func-4
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $func-4)
)

;; with default
