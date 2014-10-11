
local matrix = { };
local n = 4;
for i = 1,n do
  matrix[i]={}
  for j= 1,n do
    matrix[i][j]=j+n*(i-1);
    print(matrix[i][j]);
  end
end

