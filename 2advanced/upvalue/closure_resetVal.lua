-- 在一些语言中，在函数中可以（嵌套）定义另一个函数时，如果内部的函数引用了外部的函数的变量，则可能产生闭包。运行时，一旦外部的 函数被执行，一个闭包就形成了，闭包中包含了内部函数的代码，以及所需外部函数中的变量的引用。其中所引用的变量称作上值(upvalue)。
-- a closure (also lexical closure or function closure) is a function or reference to a function together with a referencing environment — a table storing a reference to each of the non-local variables (also called free variables or upvalues) of that function.

local x = 5

local function f() -- we use the "local function" syntax here, but that's just for good practice, the example will work without it
  print(x)
end

f() --> 5
x = 6
f() --> 6

-- ############
-- With the local keyword, it's all explicit: without local, you change the existing variable, with it, you create a new one.
