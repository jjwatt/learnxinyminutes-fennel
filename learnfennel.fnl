;; Comments start with semicolons.

;; Fennel is written in lists of things inside parentheses, separated
;; by whitespace.

;; The first thing in parentheses is a function or macro to call, and
;; the rest are the arguments.

;;----------------------------------------------------
;; 1. Primitives and Operators
;;----------------------------------------------------

;; (local ...) defines a var inside the whole file's scope.
(local s "walternate") ;; Immutable strings like Python.

;; local supports destructuring and multiple value binding.
;; (covered later).

;; Strings are utf8 byte arrays
"λx:(μα.α→α).xx"              ; can include Unicode characters

;; .. will create a string out of it's arguments.
;; It will coerce numbers but nothing else.
(.. "Hello" " " "World") ; => "Hello World"

;; (print ...) will print all arguments with tabs in between
(print "Hello" "World") ; "Hello World" printed to screen

(local num 42) ;; Numbers can be integer or floating point.

;; Math is straightforward
(+ 1 1) ; => 2
(- 2 1) ; => 1
(* 1 2) ; => 2
(/ 2 1) ; => 2.0
;; TODO: Lua has more operators than this. e.g. //

;; Equality is =
(= 1 1) ; => true
(= 2 1) ; => false

;; Nesting forms works as you expect
(+ 1 (- 3 2)) ; = 1 + (3 - 2) => 2

;; Comparisons
(> 1 2) ; => false
(< 1 2) ; => true
(>= 1 1) ; => true
(<= 1 2) ; => true
(not= 1 2) ; => true

;; TODO: find some bitwise operator examples
;; (lshift 1) ; => 2

;;----------------------------------------------------
;; 2. Types
;;----------------------------------------------------

;; Fennel uses Lua's types for booleans, strings & numbers.
;; Use `type` to inspect them.
(type 1) ; => "number"
(type 1.0) ; => "number"
(type "")  ; => "string"
(type false) ; => "boolean"
(type nil) ; => "nil"

;; Booleans
true ; for true
false ; for false
(not true) ; => false
(and 0 false) ; => false
(or false 0) ; => 0

;; Collections & Sequences
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; tables are the only compound data structure in Lua and fennel.
;; Similar to php arrays or js objects, they are
;; hash-lookup dicts that can also be used as lists.

;; tables can be treated as sequential or non-sequential: as hashmaps
;; or lists/arrays.

;; Using tables as dictionaries / maps:
(local t {:key1 "value1" :key2 false})

;; String keys can use dot notation:
(print t.key1)         ;; Prints "value1"

;; Setting table keys and values
(tset t :newKey {})    ;; Adds a new key/value pair.
(tset t :key2 nil)     ;; Removes key2 from the table.

;; Literal notation for any (non-nil) value as key

;; length string or table length
(+ (length [1 2 3 nil 8]) (length "abc")) ; => 8

;; . table lookup looks up a given key in a table. Multiple arguments
;; will perform nested lookup.
(. t :key1)

(let [t {:a [2 3 4]}] (. t :a 2)) ; => 3

;; If the field name is a string known at compile time, you don't need
;; this and can just use table.field (dot notation).

;; Nil-safe ?. table lookup
;; Looks up a given key in a table. Multiple arguments will perform
;; nested lookup. If any subsequent keys is not presnet, will
;; short-circuit to nil.
(?. t :key1) ; => "value"
(let [t {:a [2 3 4]}] (?. t :a 4 :b)) ; => nil
(let [t {:a [2 3 4 {:b 42}]}] (?. t :a 4 :b)) ; => 42

; Functions
;;;;;;;;;;;;;;;;;;;;

;; Use fn to create new functions. A function always returns its last
;; statement.
(fn [] "Hello World") ; => #<function: 0x55630f9d7f20>

; (You need extra parens to call it)
((fn [] "Hello World")) ; => "Hello World"

;; Assign a function to a var
(local hello-world (fn [] "Hello World"))
(hello-world) ; => "Hello World"

;; You can use fn and name a function.
(fn hello-world [] "Hello World") ; => "Hello World"

;; The [] is the list of arguments to the function.
(fn hello [name]
  (.. "Hello " name))
(hello "Steve") ; => "Hello Steve"

;; Will accept any number of arguments. ones in excess of the declared
;; ones are ignored, and if not enough arguments are supplied to cover
;; the declared ones, the remaining ones are given values of nil.

;; Providing a name that's a table field will cause it to be inserted
;; in a table instead of bound as a local
(local functions {})

(fn functions.p [x y z]
  (print (* x (+ y z))))

;; equivalent to:
(set functions.p (fn [x y z]
                   (print (* x (+ y z)))))

;; Like Lua, functions in Fennel support tail-call optimization,
;; allowing (among other things) functions to recurse indefinitely
;; without overflowing the stack, provided the call is in a tail
;; position.

;; The final form in this and all other function forms is used as the
;; return value.

;; (lambda [...])
;; Creates a function like fn does, but throws an error at runtime if
;; any of the listed arguments are nil, unless its identifier begins
;; with ?.
(lambda [x ?y z]
  (print (- x (* (or ?y 1) z))))

;; Note that the Lua runtime will fill in missing arguments with nil
;; when they are not provided by the caller, so an explicit nil
;; argument is no different than omitting an argument.

;; Docstrings and metadata
;; The fn, lambda, λ and macro forms accept an optional docstring.
(fn pxy [x y]
  "Print the sum of x and y"
  (print (+ x y)))

;; Hash function literal shorthand

;; hashfn is a special function that you can abbreviate as #
;; #foo expands to (hashfn foo)

;; Hash functions are anonymous functions of one form, with implicitly
;; named arguments.

#(+ $1 $2) ;; same as
(hashfn (+ $1 $2)) ; implementation detail; don't use directly
;; same as
(fn [a b] (+a b))

;; A lone $ in a hash function is treated as ana alias for $1.
#(+ $ 1)

#$ ; same as (fn [x] x) (aka the identity function
#val ; same as (fn [] val)
#[$1 $2 $3] ; same as (fn [a b c] [a b c])

;; TODO: mention lambda and how it checks args

;; Binding
;;;;;;;;;;;;;

;; Local binding: `me` is bound to "Bob" only within the (let ...)
(let [me "Bob"]
  "Alice"
  me) ; => "Bob"

;; Outside the body of the let, the bindings it introduces are no
;; longer visible. The last form in the body is used as the return
;; value.

;; Destructuring
;;;;;;;;;;;;;;;;;

;; Any time you bind a local, you can destructure it if the value is a
;; table or a function call which returns multiple values

(let [(x y z) (unpack [10 9 8])]
  (+ x y z)) ; => 27

(let [[a b c] [1 2 3]]
  (+ a b c)) ; => 6

;; If a table key is a string with the same name as the local you want
;; to bind to, you can use shorthand of just : for the key name
;; followed by the local name. This works for both creating tables and
;; destructuring them.

(let [{:msg message : val} {:msg "hello there" :val 19}]
  (print message)
  val) ; prints "hello there" and returns 19

;; When destructuring a sequential table, you can capture all the
;; remainder of the table in a local by using &

(let [[a b & c] [1 2 3 4 5 6]]
  (table.concat c ",")) ; => "3,4,5,6"

;; When destructuring a non-sequential table, you can capture the
;; original table along with the destructuring by using &as

(let [{:a a :b b &as all} {:a 1 :b 2 :c 3 :d 4}]
  (+ a b all.c all.d)) ; => 10

