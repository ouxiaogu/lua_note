print "enter function to be plotted (with variable 'x'):"
local l = io.read()
local f = assert(loadstring("local var={...};if(#var ~= 0 ) then x= var[1]; io.write(x .. '\t'); end   return x*" .. l))

-- local f = function ( ... )
--   local printResult='' ; local x = 0;
--   local var={...} ;
--   for i,v in ipairs(var) do
--     if(#var~=0 ) then x= var[1] end
--     printResult = printResult .. tostring(v) .. "\t"
--   end
--   return x*l
-- end

for i=1,20 do
  print(string.rep("*", f(i)))
end