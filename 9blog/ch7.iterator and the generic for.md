ch7.iterator and the generic for.
===================

### 1. iterators and closure
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








### 

  - name "iterator" is misleading, because our iterators do not iterate: what iterates is the for loop.
  - Maybe, "generator" would be a better name instead of "iterator".



### 2. The Semantics of the Generic for
The syntax for the generic for is as follows:
```
for <var-list> in <exp-list> do
  <body>
end 
```
We call the first variable list <var-list> as *the control variable*. It control the loop, when this variable is **nil**, the loop terminate.
The run flow of this **for** loop :
1. **Initialization**: first of all , what for loop does is to evaluate the expressions after the *in* 


Lua Highlighter example
-
<pre class="prettyprint"><code class="language-lua">function value(t)
  local i=0;
  return function( )
    i = i+1;
    return t[i]; 
  end
end</code></pre>

<kbd>ssd</kbd>