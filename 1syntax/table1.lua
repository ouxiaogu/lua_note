-- file 'table1.lua'

test = { long_x=1, y={5,6} };

-- for i, val in test do
--   print(val.i );
-- end
-- in lua line wrap embedded in print , \n is unnecessary
print ("test['long_x']: "..test['long_x'].."\n");
print ("test[\"long_x\"]: "..test["long_x"].."\n");
print("test.\"long_x\": ");
key1 = 'long_x';
print (test[1]);
print (test['y']);

a = [==[
  alo
123"]==];
print(a);

Window = { x={}, y={},foreground={ } };
window1 = Window{ x = 200, y = 300, foreground = "blue" }
print( window1['x'] );