;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; NOTE: This test was ported using port_test.py and could be cleaned up.

;; RUN: foreach %s %t wasm-opt --nominal --vtable-to-indexes -all -S -o - | filecheck %s

(module
  ;; These types have nothing we need to change.
  (type $ignore-1 (struct (field i32) (field f32)))
  (type $ignore-2 (struct (field anyref)))
  (type $ignore-3 (struct (field (ref $array))))
  (type $array (array (mut i32)))

  ;; This type should have its field changed to an i32.
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $modify-2 (struct (field f64) (field i32) (field (mut i32)) (field i64)))

  ;; CHECK:      (type $modify-1 (struct (field i32)))
  (type $modify-1 (struct (field funcref)))

  ;; This type should have just some of its fields changed.
  (type $modify-2 (struct (field f64) (field funcref) (field (mut funcref)) (field i64)))

  ;; CHECK:      (table $v-table 1 1 funcref)

  ;; CHECK:      (table $v-table_0 2 2 funcref)

  ;; CHECK:      (table $v-table_1 3 3 funcref)

  ;; CHECK:      (elem $v-table$segment (table $v-table) (i32.const 0) func $helper1)

  ;; CHECK:      (elem $v-table_0$segment (table $v-table_0) (i32.const 0) func $helper2 $helper3)

  ;; CHECK:      (elem $v-table_1$segment (table $v-table_1) (i32.const 0) func $helper3 $helper4 $helper5)

  ;; CHECK:      (func $new
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify-1
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify-1
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify-2
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:    (i64.const 1337)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify-2
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i64.const 1337)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify-2
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:    (i64.const 1337)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $new
    ;; Create some structs and write to their fields.
    (drop
      (struct.new $modify-1
        (ref.func $helper1)
      )
    )
    (drop
      (struct.new $modify-1
        ;; Write the same function a second time here.
        (ref.func $helper1)
      )
    )
    (drop
      (struct.new $modify-2
        (f64.const 3.14159)
        ;; Write different functions to different fields, which will become
        ;; different tables.
        (ref.func $helper2)
        (ref.func $helper3)
        (i64.const 1337)
      )
    )
    (drop
      (struct.new $modify-2
        (f64.const 3.14159)
        ;; Write helper3 to the first field now, so the function should appear
        ;; in both tables.
        (ref.func $helper3)
        ;; Write a new function to the second table.
        (ref.func $helper4)
        (i64.const 1337)
      )
    )
    (drop
      (struct.new $modify-2
        (f64.const 3.14159)
        ;; Repeat from before.
        (ref.func $helper3)
        ;; Write yet another new function to the second table.
        (ref.func $helper5)
        (i64.const 1337)
      )
    )
  )

  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block (result funcref)
  ;; CHECK-NEXT:    (table.get $v-table
  ;; CHECK-NEXT:     (struct.get $modify-1 0
  ;; CHECK-NEXT:      (ref.null $modify-1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block0 (result funcref)
  ;; CHECK-NEXT:    (table.get $v-table_0
  ;; CHECK-NEXT:     (struct.get $modify-2 1
  ;; CHECK-NEXT:      (ref.null $modify-2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block1 (result funcref)
  ;; CHECK-NEXT:    (table.get $v-table_1
  ;; CHECK-NEXT:     (struct.get $modify-2 2
  ;; CHECK-NEXT:      (ref.null $modify-2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (block (result funcref)
        (struct.get $modify-1 0 (ref.null $modify-1))
      )
    )
    (drop
      (block (result funcref)
        (struct.get $modify-2 1 (ref.null $modify-2))
      )
    )
    (drop
      (block (result funcref)
        (struct.get $modify-2 2 (ref.null $modify-2))
      )
    )
  )

  ;; CHECK:      (func $helper1
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper1)
  ;; CHECK:      (func $helper2
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper2)
  ;; CHECK:      (func $helper3
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper3)
  ;; CHECK:      (func $helper4
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper4)
  ;; CHECK:      (func $helper5
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper5)
)

;; Don't crash on an empty module
(module
)

;; Subtyping: verify that subtypes all share the same table for each field.
(module
  ;; Each type adds a new funcref field.
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $C (struct (field i32) (field i32) (field i32)) (extends $B))

  ;; CHECK:      (type $B (struct (field i32) (field i32)) (extends $A))

  ;; CHECK:      (type $A (struct (field i32)))
  (type $A (struct (field funcref)))
  (type $B (struct (field funcref) (field funcref)) (extends $A))
  (type $C (struct (field funcref) (field funcref) (field funcref)) (extends $B))

  ;; CHECK:      (table $v-table 2 2 funcref)

  ;; CHECK:      (table $v-table_0 2 2 funcref)

  ;; CHECK:      (table $v-table_1 1 1 funcref)

  ;; CHECK:      (elem $v-table$segment (table $v-table) (i32.const 0) func $helper1 $helper2)

  ;; CHECK:      (elem $v-table_0$segment (table $v-table_0) (i32.const 0) func $helper3 $helper4)

  ;; CHECK:      (elem $v-table_1$segment (table $v-table_1) (i32.const 0) func $helper5)

  ;; CHECK:      (func $new
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $A
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $B
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $C
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $new
    ;; Create some structs and write to their fields.
    (drop
      (struct.new $A
        (ref.func $helper1)
      )
    )
    (drop
      (struct.new $B
        (ref.func $helper2)
        (ref.func $helper3)
      )
    )
    (drop
      (struct.new $C
        ;; Reuse the middle struct's reference. We should share not just the
        ;; table but also the index.
        (ref.func $helper2)
        ;; Add a new reference to the table.
        (ref.func $helper4)
        ;; This is our new field.
        (ref.func $helper5)
      )
    )
  )

  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table
  ;; CHECK-NEXT:    (struct.get $A 0
  ;; CHECK-NEXT:     (ref.null $A)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table
  ;; CHECK-NEXT:    (struct.get $B 0
  ;; CHECK-NEXT:     (ref.null $B)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table_0
  ;; CHECK-NEXT:    (struct.get $B 1
  ;; CHECK-NEXT:     (ref.null $B)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table
  ;; CHECK-NEXT:    (struct.get $C 0
  ;; CHECK-NEXT:     (ref.null $C)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table_0
  ;; CHECK-NEXT:    (struct.get $C 1
  ;; CHECK-NEXT:     (ref.null $C)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (table.get $v-table_1
  ;; CHECK-NEXT:    (struct.get $C 2
  ;; CHECK-NEXT:     (ref.null $C)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $A 0 (ref.null $A))
    )
    (drop
      (struct.get $B 0 (ref.null $B))
    )
    (drop
      (struct.get $B 1 (ref.null $B))
    )
    (drop
      (struct.get $C 0 (ref.null $C))
    )
    (drop
      (struct.get $C 1 (ref.null $C))
    )
    (drop
      (struct.get $C 2 (ref.null $C))
    )
  )

  ;; CHECK:      (func $helper1
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper1)
  ;; CHECK:      (func $helper2
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper2)
  ;; CHECK:      (func $helper3
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper3)
  ;; CHECK:      (func $helper4
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper4)
  ;; CHECK:      (func $helper5
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper5)
)

(module
  ;; Test that we update struct.new in global locations.

  ;; CHECK:      (type $modify (struct (field i32)))
  (type $modify (struct (field funcref)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (global $global (ref $modify) (struct.new $modify
  ;; CHECK-NEXT:  (i32.const 0)
  ;; CHECK-NEXT: ))
  (global $global (ref $modify) (struct.new $modify
    (ref.func $foo)
  ))

  ;; CHECK:      (table $v-table 1 1 funcref)

  ;; CHECK:      (elem (i32.const 0) $foo)

  ;; CHECK:      (func $foo
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $foo)
)

(module
  ;; Test that we do not emit non-nullable tables (which wasm does not allow).

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $modify (struct (field i32)))
  (type $modify (struct (field (ref func))))

  ;; Test that we update globals
  ;; CHECK:      (table $v-table 1 1 funcref)

  ;; CHECK:      (elem (i32.const 0) $foo)

  ;; CHECK:      (func $foo
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $modify
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $foo
    (drop
      (struct.new $modify
        (ref.func $foo)
      )
    )
  )
)
