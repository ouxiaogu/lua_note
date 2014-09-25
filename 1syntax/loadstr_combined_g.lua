print "enter function to be plotted (with variable 'x'):"
local l = io.read()
local f = assert(loadstring("return x*" .. l))
for i=1,20 do
  x = i;
  print(string.rep("*", f(i)))
end