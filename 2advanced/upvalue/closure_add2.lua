function add (x)
  return function (y)
           return x+y
         end
end

add2 = add(2)
print(add2(5)) -- 7

add0 = add
print( add0(2)(5) ) -- 7
-- When add2 is called, its body accesses the outer local variable x (function
-- parameters in Lua are local variables). However, by the time add2 is called,
-- the function add that created add2 has already returned. If x was created in the
-- stack, its stack slot would no longer exist.

