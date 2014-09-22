function clone (o)
   local new_o = {}           -- creates a new object
   local i, v = next(o,nil)   -- get first index of "o" and its value
   while i do
     new_o[i] = v             -- store them in new table
     -- print(v);
     i, v = next(o,i)         -- get next index and its value
   end
   return new_o
 end

test = { x=1, y={5,6} ,z="a string" };
clone(test);
