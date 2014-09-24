table1 = {fred='one';alpha={'two', 'three'}; 20,10; [0]='dict_val0',[111]='dict_val111'; 40,30} --

function get_val( t1 )
  local i = 0
  local n = #t1; -- table.getn(t1);
  return function (  )
    i=i+1
    if(i<=n) then
      -- print(i);
      return t1[i];
    end
  end
end

-- ### 1. for loop 1
print(#table1);
for element in get_val(table1) do
  print (element)
end

-- ### 2. for loop 2
iter_t = get_val(table1);
for element in iter_t do
  if element ~= nil then
    print(element)
  end
end

-- ### 3. while loop
-- iter_t2 = get_val(table1);
-- while true do
--   local element = iter_t2()
--   if element == nil then
--     break
--   end
--   print(element);
-- end

-- ### 4. for loop 3
-- iter_t3 = get_val(table1);
-- for i = 1, #table1, 1 do
--   local element = iter_t3();
--   if element ~= nil then
--     print(element)
--   end
-- end

