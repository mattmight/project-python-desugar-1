
Project: Desugar Python (Phase I)
=================================

In this project, you will desugar constructs in Python.

Assume Python has been parsed into the format described in
the python-to-s-expression converter for the input.



Provided utilities
------------------

Two utilities have been provided to make writing this phase easier: the
[`pywalk`](https://github.com/mattmight/pywalk) package
and [`sxpy`](https://github.com/mattmight/sexp-to-python).


### pywalk

The `pywalk` package provides facilities for walking over Python abstract syntax
trees and making point transformations.


### sxpy

The `sxpy` utility converts a Python AST in s-expression form back into running
Python code.



Required transformations
------------------------

### Canonicalize return

Return should always take a return value.

In the case of a blank return:

```
  return
```

it should become:

```
  return None
```


### Decorator dropping

Decorators should be dropped to function calls:

```
@<decorator>
def <name>(<parameters>):
  <body>
```

becomes:

```
def <name>(<parameters>):
  <body>
<name> = <decorator>(<name>)
```

just as:

```
@<decorator>
class <name>(<parameters>): 
  <body>
```

becomes:

```
class <name>(<parameters>): 
  <body>
<name> = <decorator>(<name>)
```

### Default dropping

Default values for parameters should be dropped into assignments 
after the procedure definition.

For example:

```
def f(x = g()): pass
```

becomes:

```
def f(x): pass
f.__defaults__  = (g(),)
f.__kwdefaults__ = None
```

while

```
def f(a=10,*,b=20): pass
```

becomes:

```
def f(a,*,b): pass

f.__defaults__ = (10,)
f.__kwdefaults__ = {"b":20}
```


### Annotation dropping

Annotations (types) on parameters should be dropped to an assignment below a
procedure.

For example, 

```
def f(x : int) -> int:
  return x + 1
```

should become:

```
def f(x):
  return (x) + (1)

f.__annotations__ = {"return":int,"x":int}
```


### `for`-loop elimination

All `for` loop should be converted to `while` loops.

The following transformation is recommended:

```
for <targets> in <iterator>:
   <body>
```

becomes:

```
$tmp2 = ($tmp1 for $tmp1 in <iterator>)
while True:
  try:
    <targets> = $tmp2.__next__()
  except StopIteration:
    break
  <body>
```


###  Assignment flattening / `*`-elimination

Starred expressions, lists and tuples should be eliminated from assignment
forms by flattening assignments out.

For instance:

```
(a,b,c) = somelist
```

becomes:

```
$tmp = list(somelist)
a = ($tmp)[0]
b = ($tmp)[1]
c = ($tmp)[2]
```

while:

```
(a,b,*c,d,e) = elts
```

becomes:

```
$tmp = list(elts)
a = ($tmp)[0]
b = ($tmp)[1]
c = ($tmp)[2:-2:]
d = ($tmp)[-2]
e = ($tmp)[-1]
```


### Class elimination

Because classes in Python are objects and the `type` primitive can create
classes dynamically, all class declarations can be eliminated and desugared
into a combination of function definitions and function calls.

For instance:

```
class X:

  y = 10

x = X()

print(x.y)
```

becomes:

```
def $tmp1($tmp2 = object,*$tmp3,metaclass = type,**$tmp4):
  __dict__ = {}
  (__dict__)["y"] = 10
  return metaclass("X",($tmp2,) + $tmp3,__dict__)

X = $tmp1()
x = X()
print(x.y)
```



Simplifications
---------------

  1. The transformation need not be "error-raise-preserving."

     That is, you may opt to use a transformation that does not raise an
     `Error`-level exception when Python would have raised an `Error`-level
     exception.
  
     Rather than raise an error, your implementation may do anything.

  2. You may assume that the names in `builtins` are never assigned.  (This
     will make it easier to write hygienic transformations that want to 
     desugar into builtins.)  For example, you can assume `list` will always
     be the `list` class.





Output grammar
--------------

The output must conform to the following grammar:


```
<mod> ::= (Module <stmt>*)

<stmt> ::=

        (FunctionDef
          (name <identifier>)
          ; NOTE: <arguments> is simplified below.
          (args <arguments>) 
          (body <stmt>*)
          (decorator_list)
          (returns #f))

      | (Return <expr>) 

      | (Delete <expr>*) 

      ; NOTE: <expr> no longer has starred form.
      | (Assign (targets <expr>) (value <expr>)) 

      | (AugAssign <expr> <operator> <expr>)  

      | (While (test <expr>) (body <stmt>*) (orelse <stmt>*))

      | (If (test <expr>) (body <stmt>*) (orelse <stmt>*))

      | (With [<withitem>*] <stmt>*)

      | (Raise <expr>)  
      | (Raise <expr> <expr>)

      | (Try (body <stmt>*)
             (handlers <excepthandler>*)
             (orelse <stmt>*)
             (finalbody <stmt>*))

      | (Assert <expr>)  
      | (Assert <expr> <expr>)

      | (Import <alias>*)
      | (ImportFrom (module <identifier?>)
                    (names <alias>*)
                    (level <int?>))

      | (Global <identifier>+)
      | (Nonlocal <identifier>+)

      | (Expr <expr>)

      | (Pass) 
      | (Break)
      | (Continue)

      ;; Added:

      ; Use Local to specify variables assinged here:
      | (Local <identifier>+) 

      ; Use Comment to specify a comment (useful in debugging):
      | (Comment <string>)


<expr> ::=
       (BoolOp <boolop> <expr>*)
     | (BinOp <expr> <operator> <expr>)
     | (UnaryOp <unaryop> <expr>)

     | (Lambda <arguments> <expr>)

     | (IfExp <expr> <expr> <expr>)

     | (Dict (keys <expr>*) (values <expr>*))
     
     | (Set <expr>*)
     | (ListComp <expr> <comprehension>*)
     | (SetComp <expr> <comprehension>*) ; call to ListComp
     | (DictComp <expr> <expr> <comprehension>*)

     | (GeneratorExp <expr> <comprehension>*)

     | (Yield)  | (Yield <expr>)

     | (YieldFrom <expr>)

     | (Compare (left        <expr>) 
                (ops         <cmpop>*)
                (comparators <expr>*))

     | (Call (func <expr>)
             (args <expr>*)
             (keywords <keyword>*)
             (starags <expr?>)
             (kwargs <expr?>))

     | (Num <number>)
     | (Str <string>)
     | (Bytes <byte-string>)

     | (NameConstant <name-constant>)
     | (Ellipsis)

     ; the following expression can appear in assignment context:
     ; NOTE: Starred form has been eliminated:
     | (Attribute <expr> <identifier>)
     | (Subscript <expr> <slice>)
     | (Name <identifier>)
     | (List <expr>*)
     | (Tuple <expr>*)

<name-constant> ::= True | False | None

<slice> ::= (Slice <expr?> <expr?> <expr?>)
         |  (ExtSlice <slice>*) 
         |  (Index <expr>)

<boolop> ::= And | Or 

<operator> ::= Add | Sub | Mult | Div | Mod | Pow | LShift 
               | RShift | BitOr | BitXor | BitAnd | FloorDiv

<unaryop> ::= Invert | Not | UAdd | USub

<cmpop> ::= Eq | NotEq | Lt | LtE | Gt | GtE | Is | IsNot | In | NotIn

<comprehension> ::= [for <expr> in <expr> if <expr>*]

<excepthandler> ::= [except <expr?> <identifier?> <stmt>*]

<arguments> ::= (Arguments
                   (args <arg>*)
                   (arg-types #f*)
                   (vararg <arg?>) 
                   (kwonlyargs <arg>*)
                   (kwonlyarg-types #f*)
                   (kw_defaults #f*)
                   (kwarg <arg?>) 
                   (defaults #f*))
 
<arg> ::= <identifier>

<keyword> ::== [<identifier> <expr>]

<alias> ::= [<identifier> <identifier?>]

<withitem> ::= [<expr> <expr?>]


<arg?> ::= <arg> | #f

<expr?> ::= <expr> | #f

<int?> ::= <int> | #f

<identifier?> ::= <identifier> | #f
```



