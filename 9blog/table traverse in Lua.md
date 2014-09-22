## Lua Syntax

### Associative arrays traverse

In computer science, an **associative array**, **map**, **symbol table**, or **dictionary** is an abstract data type composed of a collection of *(key, value)* pairs, such that each possible key appears at most once in the collection.
Operations associated with this data type allow:
- the addition of pairs to the collection
- the removal of pairs from the collection
- the modification of the values of existing pairs
- the lookup of the value associated with a particular key

*fig 1: a associative arrays example*

```
  table1 = {
    fred = 'one';             
    alpha= {'two', 'three'}; 
    20,10; 
    [0]='dict_val0',
    [111]='dict_val111'; 
    40,30} 
``` 

notice of this table:
- **key** should not have a quotation , so 'fred' = 'two' is not correct; and ***key** would not accept a number, a number would be interpreted as a array index, must write within a pair of bracket `[]`, *[0]='dict_val0'*
- just like double quotes `"` is the same with single quote `'` in Lua, comma `,` and semicolon `;` is equivalent in Lua ,but for the  uniformity of programming style, we can use comma `,` as the same type of value type, and semicolon `;` for different value type.  
- in this table
  + {20,10,40,30} is array with index of 1,2,3,4
  + {fred = 'one';             
      alpha= {'two', 'three'};
      [0]='dict_val0';
      [111]='dict_val111'  } are pairs type data. *(key, value)* 

#### pairs & ipairs : traverse all pairs & array

then we will use **pairs** and **ipairs** to traverse the table

*fig 2. traverse table with pairs*

```
  for i, v in pairs(table1) do
    print(v);
  end
```

**pairs** : transverse all the array index&values and pairs key&value.

>pairs output:
  20
  10
  40
  30
  dict_val0
  one
  dict_val111
  table: 004EAED0

*fig 3. traverse table with pairs*
```
  for k in ipairs(table1) do
    print(k);
  end
```

**ipairs**: transverse all the array indexes&values: 

>ipairs output:
  1
  2
  3
  4

when use   for i,v in ipairs(table1) do print(v) end , it will print all the array values.

#### unpack : traverse continuous array index
the original Lua function **unpack** is write in C. **unpack** can return a continuous array until meeting a line-end symbol. 

*fig 4. an example of unpack function*

```
  f = string.find
  a = {"hello", "ll"}
  print(f(unpack(a)))
```

we can also define a **unpack** function in Lua

*fig 5. self defined  unpack function*

```
  function unpack(t, i)
    i = i or 1
    if t[i] then
      return t[i], unpack(t, i + 1)
    end
  end
  table1 = { 'have', 'a', 'nice', 'life',[1001]='god',[1002]='knows' };
  print(unpack(table1, 2) );
  print(unpack(table1, 1001) );
```