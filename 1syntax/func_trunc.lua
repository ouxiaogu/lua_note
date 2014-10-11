truncate = function(a, n)
-- generally, can keep 3 more digital numbers
    if(a == nil)then return nil end
    if(n == nil)then n = 3 end
    local b = math.pow(10, n)
    a = math.floor(a*b)
    a = a/b
    return a
end

best_focus = 1.2421
best_focus2 = math.floor(best_focus+0.5);
print(best_focus2)

best_focus3= truncate(best_focus)
print(best_focus3)
