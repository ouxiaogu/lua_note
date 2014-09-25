Compilation, Execution, and Errors
===

dofile and require
----
### dofile & loadfile

_dofile_ as a kind of primitive operation to run chunks
of Lua code. There is embedded _loadfile_ in _dofile_.

- _loadfile_ ：it only compiles the chunk and returns the compiled chunk as a function
- _dofile_ : run the compiled chunk when call _dofile_
```
function dofile (filename)
  local f = assert(loadfile(filename))
  return f()
end
```
### loadstring
_loadstring_ is similiar with _loadfile_, only difference is _loadstring_ read chunk from a string.

>**Note** 
>loadstring does not compile with lexical scoping.
As the code below, The g function manipulates the local i, as expected, but f manipulates a global i, because _loadstring_ always compiles its strings in the global environment. 
- g function generate a closure, the g function and the anonymous function only compile once, to call the g function the second time and after ,Lua will read the upvalue directly. 
- f function will be compiled , each time it it called. 
- Given to this property , _loadstring_ often is used to run external code(e.eg. user_defined chunk).
```
i = 32
local i = 0
f = loadstring("i = i + 1; print(i)")
g = function () i = i + 1; print(i) end
f() --> 33
g() --> 1
```

In the above cases,_loadstring_ expects a chunk, that is, **statements**. If you want to evaluate **expression** , you must prefix it with **return**.

e.g.

print "enter your expression:"
local l = io.read()
local func = assert(loadstring("return " .. l))  --> equal to local func() return i end
print("the value of your expression is " .. func())


### function definition and run

