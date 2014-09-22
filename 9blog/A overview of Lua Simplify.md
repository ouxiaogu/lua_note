##A overview of Lua

*code 1 : An interactive interpreter for Lua*

    #include <stdio.h>
    #include "lua.h"              /* lua header file */
    #include "lualib.h"           /* extra libraries (optional) */

    int main (int argc, char *argv[])
    {
      char line[BUFSIZ];
      iolib_open();               /* opens I/O library (optional) */
      strlib_open();              /* opens string lib (optional) */
      mathlib_open();             /* opens math lib (optional) */
      while (gets(line) != 0)
      lua_dostring(line);
    }

### 1 main concepts of Lua:


1. embedded programming language
2. design for support procedural programming
3. a library of C functions to be linked to host applications
4.  The host can invoke functions in the library to execute a piece of code in Lua, write and read Lua variables, and register C functions to be called by Lua code.
5. Moreover, *fallbacks* can be specified to be called whenever Lua does not know how to proceed.
6. creating customized programming languages sharing a single syntactical framework
7. Lua is language framework
8. easy to write an interactive , standalone interpreter for Lua

### 2 Lua environment & execution unit 

1. All statements in Lua are executed in a global environment, which keeps all global variables and functions.This environment is initialized at the beginning of the host program and persists until its end.
2. The unit of execution of Lua is call a chunk 
  1. a chunk include statements and function definition
  2. a chunk execute flow
    1. compile all its functions and statements, and add the functions to the global environment
    2. the statements execute in sequential order


### 3 Variables and values in lua

*Code2.  simple config method*

    width = 420
    height = width*3/2 -- ensures 3/2 aspect ratio
    color = "blue"

1. as code2 , three global variables are defined , and values are assigned to them
2. Lua is a dynamically typed language : `variables have no types` ; `only values do`
3. It means , `all values carry their own type.` and `no variable type definition in Lua`

more powerful configurations can be written using flow control and function definitions. 

*code 3. Config file using functions*

    function Bound (w, h)
      if w < 20 then w = 20
      elseif w > 500 then w = 500
      end
      local minH = w*3/2             -- local variable
      if h < minH then h = minH end
      return w, h
    end

    width, height = Bound(420, 500)
    if monochrome then color = "black" else color = "blue" end

1. Pascal-like syntax, with reserved words and explicitly terminated blocks; 
2. semicolons are optional.
3. familiar , robust and easily parsed.
4. functions can return multiple values, and multiple assignments can be used to collect these values
5. reference pointer like parameter passing is discarded , that less many small semantic difficulties

#### Lua Values type

1. Functions —— *first class* value in Lua
  1. a function definition creates a value of type **function**, and assign this value to a global variable ( e.g. **Bound** in code 3) .
  2. Like any other value, function values can be `stored in variables`, `passed as arguments to other functions` and `returned as results` .
  3. This feature greatly simplifies the implementation of object-oriented facilities
2. basic types
  - **number**(floats)
  - **string**
  - **function**
  
3. three other types
  - **nil** :  
    - has a single value, aslo called **nil**, different from any other value;
    - all value will be set as nil before first assignment. Thus , uninitialized variables error is not existed in Lua. 
    - also use nil in a context where an actual value is needed but result in an execution error
  - **userdata** 
    + arbitrary host data
    + represented as void* C pointers
    + can only be used as assignment and equality test.
  - **table**
    + associative arrays
    + arrays that can be indexed not only with integers, but with strings, reals, tables, and function values.

### 4 Associative arrays

1. Associative arrays are a powerful language construct 
2. Most typical data containers, like ordinary arrays, sets, bags, and symbol tables, can be directly implemented by tables. 
3. Tables can also simulate records by simply using field names as indices.
4. Lua supports to use `a.name` as syntactic sugar for `a["name"]`.

##### 4.1 tables pros&cons
1. tables in Lua are not  bound to a variable name;
2. they are dynamically created objects that can be manipulated much like pointers in conventional languages. 
3. The disadvantage of this choice is that a table must be explicitly created before used.
4. The advantage is that tables can freely refer to other tables, and therefore have expressive power to model recursive data types, and to create generic graph structures, possibly with cycles. 

*code 4.  A circular linked list in Lua*

      list = {}                    -- creates an empty table
      current = list
      i = 0
      while i < 10 do
        current.value = i
        current.next = {}
        current = current.next
        i = i+1
      end
      current.value = i
      current.next = list

##### 4.2 table create methods

1. simplest, by expression *{}*
  
  influenced by the format of BibTex,
  ```
    @inproceedings{liu2012full,
    title={A full-chip 3D computational lithography framework},
    author={Liu, Peng and Zhang, Zhengfan and Lan, Song and Zhao, Qian and Feng, Mu and Liu, Hua-yu and Vellanki, Venu and Lu, Yen-wen},
    booktitle={SPIE Advanced Lithography},
    pages={83260A--83260A},
    year={2012},
    organization={International Society for Optics and Photonics}
  }
  ```

  table definition could be like this:
    *exp = { key1= {val1_1}, key2={ val2_1, val2_2 } }* 
    
      window1 = {x = 200, y = 300, foreground = "blue"}
    

##### 4.3 create list
just like table, list can created by *{}*

  ```
  colors = {"blue", "yellow", "red", "green", "black"}
  ```
  which is equivalent to:
  ```
    colors = {}
    colors[1] = "blue";  colors[2] = "yellow"; colors[3] = "red"
    colors[4] = "green"; colors[5] = "black"
  ```

> **confused** : high level abstractions ?
How to implement high level abstractions in Lua.
As it said ," Lua is dynamically typed, it provides user controlled type constructors."

```
  window1 = Window{ x = 200, y = 300, foreground = "blue" }
```


##### 4.4 table traverse

###### *next* function

*code 5.  Function to clone a generic object using next*

```
  function clone (o)
    local new_o = {}           -- creates a new object
    local i, v = next(o,nil)   -- get first index of "o" and its value
    while i do
      new_o[i] = v             -- store them in new table
      i, v = next(o,i)         -- get next index and its value
    end
    return new_o
  end
```

*next* 
  *next (table , index)*  traverses a table
  - index is *nil*, return *first index of given table* and *the value of first index*.
  - index is not *nil*, return the next index and its value.

*nextvar*
  *nextvar(index)*  traverses the global variables of Lua

*code 6: Function to save Lua environment*
```
  function save ()
    local env = {}             -- create a new table
    local n, v = nextvar(nil)  -- get first global var and its value
    while n do
      env[n] = v               -- store global variable in table
      n, v = nextvar(n)        -- get next global var and its value
    end
    return env
  end
```

*code 7: Function to restore a Lua environment.*
```
  function restore (env)
    -- save some built-in functions before erasing global environment
    local nextvar, next, setglobal = nextvar, next, setglobal
    -- erase all global variables
    local n, v = nextvar(nil)
    while n do
      setglobal(n, nil)
      n, v = nextvar(n)
    end
    -- restore old values
    n, v = next(env, nil)      -- get first index; v = env[n]
    while n do
     setglobal(n, v)           -- set global variable with name n
     n, v = next(env, n)
    end
  end
```

#### 4.5 object-oriented programming of table

Because functions are first class values, `table fields` can refer to functions. This property allows the implementation of some interesting object-oriented facilities, which are made easier by syntactic sugar for defining and calling `methods`.

1. `method` definition
  ```
    function object:method (params)
      ```
    end
  ```
  Which is equivalent to
  ```
    function dummy_name (self, params)
      ```
    end
    object.method = dummy_name
  ```
That is, an anonymous function is created and stored in a table field; moreover, this function has a hidden parameter called *self*.

2. `method` call
  ```
      receiver:method(params)
  ```
  which is translated to
  ```
    receiver.method(receiver,params)
  ```
  In words, the receiver of the method is passed as its first argument, giving the expected meaning to the parameter self.    

difference and common of C++ like class in Lua:
- it does not provide `information hiding`
- it does not provide classes; each object carries its operations.
- this construction is extremely light (only syntactic sugar), and classes can be simulated using inheritance,

### 5 fallbacks
Their own functions to handle error conditions; such functions are called *fallback functions*.

call the **setfallback** function to set a fallback function. With two arguments: a string indentifying the fallback, and the new function to be called whenever the corresponding condition occurs.

Lua supports the following fallbacks, identified by the given strings:
- "**arith**", "**order**", "**concat**" ` - These fallbacks are called when an operation is applied to invalid operands. They receive three arguments: the two operands and a string describing the offended operator ("**add**", "**sub**", : : : ). Their return value is the final result of the operation. The default functions for these fallbacks issue an error.
- "**index**" - When Lua tries to retrieve the value of an index not present in a table, this fallback is called.It receives as arguments the table and the index. Its return value is the final result of the indexing operation. The default function returns nil.
- "**gettable**", "**settable**" - Called when Lua tries to read or write the value of an index in a non table value. The default functions issue an error.
- "**function**" - Called when Lua tries to call a non function value. It receives as arguments the non unction value and the arguments given in the original call. Its return values are the final results of the call operation. The default function issues an error.
- "**gc**" - Called during the garbage collection. It receives as argument the table being collected, and nil to signal the end of garbage collection. The default function does nothing.

#### 5.1 Using fallbacks

*code 8: An example to use a more object oriented style of interpreting*

```
  function dispatch (receiver, parameter, operator)
    if type(receiver) == "table" then
      return receiver[operator](receiver, parameter)
    else
      return oldFallback(receiver, parameter, operator)
    end
  end
  oldFallback = setfallback("arith", dispatch)
```

- With this case, if **a** is a table, then expressions like **a+b**,will been executed as **a:add(b)**.
- Notice the use of the global variable **oldFallback** to chain fallback functions.

##### Another unusual facility provided by fallbacks is the reuse of Lua's parser. 语法剖析程式

``` 
  (a*a+b*b)*(a*a-b*b)/(a*a+b*b+c)+(a*(b*b)*c) 
```

z1=mul(a,a) z2=mul(b,b) z3=add(z1,z2)
z4=sub(z1,z2) z5=mul(z3,z4) z6=add(z3,c)
z7=div(z5,z6) z8=mul(a,z2) z9=mul(z8,c)
z10=add(z7,z9)

##### arithmetic expressions to represent complex calculations

*code 9.An optimizing arithmetic expression compiler in Lua.*
```
  n=0                            -- counter of temporary variables
  T={}                           -- table of temporary variables

  function arithfb(a,b,op)
    local i=op .. "(" .. a.name .. "," .. b.name .. ")"
    if T[i]==nil then             -- expression not seen yet
      n=n+1
      T[i]=create("t"..n)         -- save result in cache
      print(T[i].name ..'='..i)
    end
    return T[i]
  end

  setfallback("arith",arithfb)   -- set arithmetic fallback

  function create(v)             -- create symbolic variable
    local t={name=v}
    setglobal(v,t)
    return t
  end

  create("a") create("b") create("c") ``` create("z")

  while 1 do                     -- read expressions
    local s=read()
    if (s==nil) then exit() end
    dostring("E="..s)             -- execute fake assignment
    print(s.."="..E.name.."\n")
  end
```

#### 5.2 Inheritance via fallbacks
Certainly, one of the most interesting uses of fallbacks is in implementing inheritance in Lua.
1. fallback and callback common & difference ？
2. Simple inheritance allows an object to look for the value of an absent field in another object, called its *parent*; in particular, this field can be a method. 

*code 10. Implementing simple inheritance in Lua.*
```
  function Inherit (object, field)
    if field == "parent" then     -- avoid loops
      return nil
    end
    local p = object.parent       -- access parent object
    if type(p) == "table" then    -- check if parent is a table
      return p[field]             -- (this may call Inherit again)
    else
      return nil
    end
  end

  setfallback("index", Inherit)
```

3. One way to implement simple inheritance in Lua is to store the parent object in a distinguished field, called parent for instance, and set an index fallback function as shown in Figure 10.
4. multiple inheritance can also be implemented.using *godparent* to achieve double inheritance , and double inheritance can model generic multiple inheritance. e.g. *a* inherits from *a1*, *a2* and *a3* in the below case.

```
  a = {parent = a1, godparent = {parent = a2, godparent = a3}}
```

### 6 Conclusion
Nowadays, many programs are written in two different languages: one for writing a powerful “virtual machine”, and another for writing single programs for this machine.Lua is a language designed specifically for the latter task. It is small: as already noted, the whole library is around six thousand lines of ANSI C. It is portable: Lua is being used in platforms ranging from PC-DOS to CRAY. It has a simple syntax and a simple semantics. And it is flexible.

some unusual mechanisms that make the language highly extensible. 
- **Associative arrays** 
  +  a strong unifying data constructor
  +  it allows more efficient algorithms than other unifying constructors like strings or lists
  +  tables in Lua are dynamically created objects with an identity, which simplify to use the tables as objects, and the addition of object-oriented facilities.
- **Fallbacks** 
  + allow programmer to extend the meaning of most built-in operations.
  + Particularly, with the fallbacks for indexing operations, different kinds of inheritance can be added to the language
  + while fallbacks for "arith" and other operators can implement dynamic overloading.
- **Reflexive facilities** 
  + for data structure traversal
  + Examples are cloning objects and manipulating the global environment.



