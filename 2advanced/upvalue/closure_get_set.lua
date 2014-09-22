local function f()
  local v = 0
  local function get()
    return v
  end
  local function set(new_v)
    v = new_v
  end
  return {get=get, set=set}
end

local t, u = f(), f()
print(t.get()) --> 0
print(u.get()) --> 0
t.set(5)
u.set(6)
print(t.get()) --> 5
print(u.get()) --> 6