## functions in Lua

As it's illustrated in "a overview of Lua", Functions is the *first class* value in Lua. first-class means:

- a function is a value with the same rights as conventional values like numbers and strings.
- can be stored in variables (both global and local) and in tables
- can be passed as arguments
- can be returned by other functions

既然函数是值，那么表达式也可以创建函数了，Lua中我们经常这样写：
```function foo (x) return 2*x end```
其实这是利用Lua提供的“语法上的甜头” （ syntactic sugar ）的结果，实际上原本的函数为：
```foo = function (x) return 2*x end```
So, a function definition is in fact a statement (an assignment, more specially)that creates a value of type `function` and assigns it to a variable.
我们用 function (x) ``` end 来定义一个function和使用 {} 创建一个table一样。

### usage 1 : higher-order function 高级函数

*fig 1: anonymous function as a parameter*
```
  network = {
    {name = "grauna", IP = "210.26.30.34"},
    {name = "arraial", IP = "210.26.30.23"},
    {name = "lua", IP = "210.26.23.12"},
    {name = "derain", IP = "210.26.23.20"},
  }
  table.sort(network, function (a,b)
                        return (a.name > b.name)
                      end
  )
```
"function (a,b) return (a.name > b.name) end" as a function type value pass to the compare function parameter, the parameter become an argument.
A function that gets another function as an argument, such as sort, is
what we call a *higher-order function*.
Higher-order functions are a powerful programming mechanism, and the use of anonymous functions to create their function arguments is a great source of flexibility.
But remember that higher order functions have no special rights; they are a direct consequence of the ability of Lua to handle functions as first-class values.

### closures 闭包
When a function is written enclosed in another function, it has full access to
local variables from the enclosing function; this feature is called **lexical scoping**(语法定界). Lexical scoping, plus first-class functions, is a powerful concept in a programming language.

#### closure as argument
*fig 2. closure example 1: closures as argument*
```
  function sortbygrade (names, grades)
    table.sort(names, function (n1, n2) 
      return grades[n1] > grades[n2] -- compare the grades
    end)
  end
```
sort函数中有个匿名函数“ function (n1, n2) return grades[n1] > grades[n2]  end ” ，匿名函数作为sortbygrade函数内部的sort的argument，但是可以访问sortbygrade的参数grades;在匿名函数内部grades不是全局变量也不是局部变量，我们称作外部的局部变量（non-local variable）或者upvalue。(For historical reasons, non-local variables are also called upvalues in Lua.)

#### closure to build another function
*fig 3. closure example 1: closures to build another function*
```
  function newCounter()
    local i = 0
    return function() -- anonymous function
      i = i + 1
      return i
    end
  end
  c1 = newCounter()
  print( c1() )       --> 1
  print( c1() )       --> 2

  c2 = newCounter()
  print( c2() )       --> 1
  print( c1() )       --> 3

  print( newCounter()() )   --> 1
  print( newCounter()() )   --> 1
  -- print( newCounter() )  --> function: 0066CB18
  -- print( newCounter() )
```

而将
fig 3中, 第10行及10行之后的代码替换为如下，

```
  c1 = newCounter
  print( c1()() )       --> 1
  print( c1()() )       --> 1

  c2 = newCounter
  print( c2()() )       --> 1
  print( c1()() )       --> 1
```
得到的结果为4个全1，和原来的code结果完全不同。

为了更清楚地展示这种情形，再举一个例子：
```
  function add (x)
    return function (y)
             return x+y
           end
  end
  add2 = add(2)
  print(add2(5))      -- 7
  add0 = add
  print( add0(2)(5) ) -- 7
```
if we use closures for functions that build other functions ,  a brief summary is as below,
- when call the new built function ,  the parameter lists of function and the anonymous function are all needed, such as *add0(2)(5)*， *newCounter()()*
- for *newCounter()()*, assume there are two layers in this func, 1st is as the parent func(like parent class in cpp) --- *newCounter()* , the anonymous func *()* 
  + let *c1=newCounter()* , then c1 is a new object of parent func
  + let *c3=newCounter*, c3 is just another name(or point) of this two layer func, every time call c3 will generate a new object

#### closures in callback functions

Closures are useful for callback functions, too.
一个最常见的例子就是计算器GUI编写，一般地，我们是一个button对应一个响应回调函数，但实际上，我们可以用closure来大大地删减这个程序。

*fig 3. closure used in callback: calculator GUI*
```
  function digitButton (digit)
    return Button{  label = tostring(digit),

                    action = function ()
                      add_to_display(digit)
                    end
                  }
  end
```

这个例子中我们假定Button是一个用来创建新按钮的工具， label是按钮的标签，action是按钮被按下时调用的回调函数。（实际上是一个闭包，因为他访问upvalue digit）。digitButton完成任务返回后，局部变量digit超出范围，回调函数仍然可以被调用并且可以访问局部变量digit。

#### closure used in function redefinition 

*fig 4. redefine the sin function*
```
  do
    local oldSin = math.sin
    local k = math.pi/180
    math.sin = function (x)
      return oldSin(x*k)
    end
  end
```
we keep the old version in a private variable; the only way to access it is
through closure.

we can also use this same technique to create secure environments, also called
*sandboxes*.
*fig 5. redefine the io.open function to create a sandbox*
```
  do
    local oldOpen = io.open
    local access_OK = function (filename, mode)
      <check access>
    end
    io.open = function (filename, mode)
      if access_OK(filename, mode) then
        return oldOpen(filename, mode)
      else
        return nil, "access denied"
      end
    end
  end
```
After this redefinition, there is no way for the program to call the unrestricted open function except through the new, restricted version.

### Non-Global Functions 非全局函数 
An obvious consequence of first-class functions is that we can store functions not only in global variables, but also in table fields and in local variables.

#### functions in table fields
Most Lua libraries use this mechanism (e.g., io.read, math.sin), define several functions in the table fields. To create such functions , we just need to combine the regular `function` definition syntax and the `table` syntax.
```
  Lib = {}
  Lib.foo = function (x,y) return x + y end
  Lib.goo = function (x,y) return x - y end
```
And the code above equal to `constructor` way:
```
  Lib = {
    foo = function (x,y) return x + y end,
    goo = function (x,y) return x - y end
  }
```
Moreover , Lua offer another syntax form:
```
  Lib = {}
  function Lib.foo (x,y) return x + y end
  function Lib.goo (x,y) return x - y end
```

#### functions as local variables , called as *local function* 局部函数
简单来说，Lua以chunk作为一个程序运行的最小单位,且将chunk当成一个function看待，是function的话就有scope，有scope就能定义局部变量。只不过这里的局部变量时局部函数。

- *(variable, value)*: local f = function (<params>)
```
  local f = function (<params>)
    <body>
  end
  local g = function (<params>)
    <some code>
    f() -- function 'f' is visible here, because 'f()' is effective in the scope of this chunk 
    <some code>
    end
```
- Lua *syntactic sugar* local function f(<params>)
```
  local function f (<params>)
    <body>
  end
```

####recursive local function 

需要注意下， *recursive local function 递归形式的局部函数*.先看下面一段代码。
```
  local fact = function (n)
    if n == 0 then return 1
    else return n*fact(n-1) --> .lua:3: in function 'fact', attempt to call global 'fact' (a nil value); .lua:6: in main chunk
    end
  end
  print( fact(4) )
```
上面这段程序的错误在于，在return调用fact(n-1)时，the local function *fact()* is not yet defined in this chunk. 
>note
  - Personally, I think the difference here is :
  - local function is visible , depend on this local function have been defined in the chunk.
  - however, from the view of *fact(n-1)* , the function *fact* is just a local value in the scope of this function, but the chunk.

因而，只会转而去搜索全局变量fact，但根本没有全局变量的fact函数，导致了error。
正确的方式应该为：
*fig 6.  recursive local function*
```
  local fact
  fact = function (n)
    if n == 0 then return 1
    else return n*fact(n-1)
    end
  end
```

有趣的是，recursive local function in "syntactic sugar" form. 

##### recursive local function in "syntactic sugar" form
*fig 7.  recursive local function 2*
```
  local function fact (n)
    if n == 0 then return 1
    else return n*fact(n-1)
    end
  end
```
this code is bug-free, because when a "syntactic sugar" form definition:
``` local function foo (<params>) <body> end ```
it is interpreted in following way:
```
  local foo
  foo = function (<params>) <body> end
```
so code in *fig 7* is just exactly the same with *fig 6*.

### proper tail calls 合理的尾调用
Another interesting feature of functions in Lua is that Lua does tail-call elimination. (This means that Lua is properly tail recursive, although the concept does not involve recursion directly.)
A _tail call_ is a _goto_  dressed as a call.A tail call happens when a function calls another as its last action, so it has nothing else to do.
```
  function f(x)
    return g(x)
  end
```
g的调用是尾调用。例子中f调用g后不会再做任何事情，这种情况下当被调用函数g结束时程序不需要返回到调用者f；所以尾调用之后程序不需要在栈中保留关于调用者的任何信息。像Lua解释器为代表的编译器能利用这种特性在处理尾调用时不使用额外的栈，We say that these implementations do tail-call elimination.
这种编译器的优势在于不用担心tail call 的数量导致的stack overflow，因为这种不会保存调用者的信息。For instance,
```
  function foo (n)
    if n > 0 then redturn foo(n - 1) end
  end
```
Lua解释器，无论输入的n为何值，都不会导致栈溢出。

A important criterion of the _tail call_ that the calling function has nothing else to do after the call.
so the examples blow are not the _tail call_.
```
  function f (x) g(x) end   -- further work: must discard the result of g(x) before returning
  return g(x) + 1           -- further work: must do the addition
  return x or g(x)          -- further work: must adjust to 1 result
  return (g(x))             -- further work: must adjust to 1 result
```


another example using _tail call_ .
*fig 8.  A maze game*
```
  function room1 ()
  local move = io.read()
  if move == "south" then return room3()
  elseif move == "east" then return room2()
  else
    print("invalid move")
    return room1() -- stay in the same room
  end
end

function room2 ()
  local move = io.read()
  if move == "south" then return room4()
  elseif move == "west" then return room1()
  else
    print("invalid move")
    return room2()
  end
end

function room3 ()
  local move = io.read()
  if move == "north" then return room1()
  elseif move == "east" then return room4()
  else
    print("invalid move")
    return room3()
  end
end

function room4 ()
  print("congratulations!")
end
```

this program use _tail call_ to run the game.

room 1 --- room 2
  |         |
room 3 --- room 4(win!)



