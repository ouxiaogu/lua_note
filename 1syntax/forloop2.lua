t = {fred='one';alpha={'two', 'three'}; 20,10; [0]='dict_val0',[111]='dict_val111'; 40,30} -- 'fred'='two' is not correct
-- print all keys of table 't'
print(t[1]);

print("values:")
for i,v in pairs(t) do
  print(v);
end
print("keys:")
for i,v in pairs(t) do
  print(i);
end
print("keys:")
for k in ipairs(t) do
  print(k);
end

--[[
-- pair : transverse all the indice ,num or strings, as map d.s.
10
20
30
40
one
1

-- ipair : numberic idx from 1 to tail as array d.s.
10
20
30
40
]]--
