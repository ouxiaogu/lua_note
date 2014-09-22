function unpack(t, i)
  i = i or 1
  if t[i] then
    return t[i], unpack(t, i + 1)
  end
end

table1 = { 'have','a','nice','life',[1001]='god',[1002]='knows' };
print(unpack(table1, 2) );
print(unpack(table1, 1001) );