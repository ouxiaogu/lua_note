-- programming in Lua 6.1 closure P.42

function newCounter()
  local i = 0
  return function() -- anonymous function
    i = i + 1
    return i
  end
end
c1 = newCounter
print( c1()() )       --> 1
print( c1()() )       --> 1

c2 = newCounter
print( c2()() )
print( c1()() )