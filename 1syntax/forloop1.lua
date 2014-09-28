function fsqrt(x)
  y = math.sqrt(x);
  return y
end

print("input a num");
x=io.read("*number");
for i=1,fsqrt(x) do
  print(i)
end

