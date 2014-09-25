ch7.iterator and the generic for.
===================

1. iterators and closure
---------------
closure play an important role in iteration.
  - An iterator is any construction that allows you to iterate over the elements of a collection.
  - In Lua, we typically represent iterators by functions: each time we call the function, it returns the "next" element from the collection.
  - Every iterator needs to keep some state between successive calls(both the previous call and the upcoming call ), so that it knows where it is and how to proceed from there.
  - Closures provide an excellent mechanism for this task.

> **note**:the sequence to call a variable in Lua
  + local variable
  + closure non-local variable 
  + global variable

a closure construction typically involves two functions: 
  + the closure itself
  + a factory : which is to create the closure , 在其中定义闭包函数和 non-local variables

```
function list_iter (t)
  local i = 0
  local n = table.getn(t)
  return function ()
    i = i + 1
    if i <= n then return t[i] end
  end
end
t = {10, 20, 30}
for element in list_iter(t) do
  print(element)
end
```
The characters of Lua generic **for** function :

1. it keeps the iterator function internally , so we do not need the iter variable;
2. it call the iterator on each new iteration;
3. it stops the loop when the iterator return nil

compare with **Loop invariants** in *introduction to algorithm*
There are 3 things about a loop invariant.

1. **Initialization**: It is true prior to the first iteration of the loop.
2. **Maintenance**: If it is true before an iteration of the loop, it remains true before the next iteration.
3. **Termination**: When the loop terminates, the invariant gives us a useful property that helps show that the algorithm is correct.
As to the 3 things of Loop invariants, the uniqueness of generic for loop in Lua is obvious :

1. **Initialization**: iterator function is defined within for loop
2. **Maintenance**: call the iterator function on each new loop
3. **Termination**: when the iterator function return nil , the for loop terminate
Look at a more advanced usage of generic **for** in Lua.
```
function allwords ()
  local line = io.read() -- current line
  local pos = 1 -- current position in the line
  return function () -- iterator function
    while line do -- repeat while there are lines
      local s, e = string.find(line, "%w+", pos)
      if s then -- found a word?
        pos = e + 1 -- next position is after this word
        return string.sub(line, s, e) -- return the word
      else
        line = io.read() -- word not found; try next line
        pos = 1 -- restart from first position
      end
    end
    return nil -- no more lines: end of traversal
  end
end
```

2. The Semantics of the Generic for 范式for的语义
---------------
The syntax for the generic for is as follows:
```
for <var-list> in <exp-list> do
  <body>
end 
```
We call the first variable list <var-list> as *the control variable*. It control the loop, when this variable is **nil**, the loop terminate.

The run flow of this **for** loop :

- 1.**Initialization**: evaluate the  expressions *exp-list*. The *exp-list*should result in the 3 values kept by the **for** loop.:  
  + the iterator function  迭代函数
  + the invariant state 状态不变量/状态常量
  + the initial value for the control variable 控制变量的初始值。
  + e.g. ```for  k, v in pairs(t) do``` *pairs( )*, *the table t to be traversed*, *return_var_list* are the above three things.
- 2.**call the iterator func** with two arguments: the invariant state and the control variable. (From the standpoint of the for construct, the invariant state has no meaning at all. The for only passes the state value from the initialization step to the calls to the iterator function.)
- 3.**assignment**:the **for** will assign the iterator function return result to *var-list*.
- 4.If the 1st value returned is **nil**, the loop terminates;
- 5.otherwise, return to the 2nd step, loop goes on, repeating the body process

>Note
The **invariant state** in `The generic for` and **the invariant of the loop** in algorithm is different ,though both of two are invariant indeed during the loop :
- The **invariant state** in `The generic for` is the invariant argument list of the iterator function in every iterations; 
-  **an invariant of a loop is a property that holds before (and after) each repetition.** when the invariant changed , generally change to **nil**, the loop then terminates.


More precisely, a construction like
```
for var_1, ..., var_n in <explist> do <block> end
```
is equivalent to the following code:
```
do
  local _f, _s, _var = <explist>
  while true do
    local var_1, ... , var_n = _f(_s, _var)
    _var = var_1
    if _var == nil then break end
    <block>
  end
end
```
So, if our iterator function is _f_, the invariant state is _s_, and the initial value for the control variable is _a0_,the control variable will loop over the values _a1 = f(s; a0), a2 = f(s; a1),..._ , until the _ai_ is **nil**.


3. stateless iterator
----
As the name implies, a stateless iterator is an **iterator** that does not keep any state by itself. Therefore, we may use the same stateless iterator in multiple loops, avoiding the cost of creating new closures.
As we discussed in previous section, for each iteration, the for loop calls its _iterator function_ with two arguments: _the invariant state_ and _the control variable_. A stateless **iterator** generates the next element for **the iteration** using only these two values.(即不用重新定义 closure，或者说 iterator func 加 upvalue，只要状态常量和控制变量在初始化时定义的 closure 中运行即可).
A typical example of this kind of iterator is _ipairs_, which iterates over all elements of an array:
```
local function iter (a, i)
  i = i + 1
  local v = a[i]
  if v then
    return i, v
  end
end

function ipairs (a)
  return iter, a, 0
end
```
*ipairs*: `factory` ; *iter*:`iterator`; When Lua calls *ipairs(a)** in a *for* loop for the 1st time , it get 3 value: the *iter* function as the `iterator`, *a* as the `invariant state`, and *0* as `the initial value for the control`. Then , Lua calls *iter(a,0)*, result in *1,a[1]*; in the 2nd iteration, it calls *iter(a,1)*, ... , until the *nil* element.

The *pairs* function, which iterates over all elements of a table, is similar,
except that the iterator function is the *next* function.
```
function pairs (t)
  return next, t, nil
end
```

4. Iterator with Complex State
---
Frequently, an iterator needs to keep more state than fits into a single invariant state and a control variable. 
- The simplest solution is to use closures.
- An alternative solution is to pack all it needs into a table and use this table as the invariant state for the iteration.
As an example of this technique, we will rewrite the iterator allwords, which
traverses all the words from the current input file.
```
local iterator -- to be defined later

function allwords ()
  local state = {line = io.read(), pos = 1}
  return iterator, state
end

function iterator (state)
  while state.line do -- repeat while there are lines
    -- search for next word
    local s, e = string.find(state.line, "%w+", state.pos)
    if s then -- found a word?
      -- update next position (after this word)
      state.pos = e + 1
      return string.sub(state.line, s, e)
    else -- word not found
      state.line = io.read() -- try next line...
      state.pos = 1 -- ... from first position
    end
  end
  return nil -- no more lines: end loop
end
```

Conclusion
-----
- name "iterator" is misleading, because our iterators do not iterate: what iterates is the for loop.
- Maybe, "generator" would be a better name instead of "iterator".

###  Four ways to write iterator

1. Whenever possible, you should try to write `stateless iterators`, those that
keep all their state in the **for** loop variables. With them, you do not create new objects when you start a loop. 
2. If you cannot fit your iteration into this model, then you should try `closures`.
3. Besides being more elegant, typically a closure is more efficient than an `iterator using tables` is: first, it is cheaper to create a closure than a table; second, access to non-local variables is faster than access to table field.
4. Use `coroutines` to write iterators.


