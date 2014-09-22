a1 = 3
a2 = 4


function save ()
  local env = {}             -- create a new table
  -- local nextvar = nextvar
  local n, v = nextvar(nil)  -- get first global var and its value
  while n do
    env[n] = v               -- store global variable in table
    print(v)
    n, v = nextvar(n)        -- get next global var and its value
  end
  return env
end

save()