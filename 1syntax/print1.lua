function list_iter (t)
	local i = 0
	local n = table.getn(t)
	return function ()
		i = i + 1
		if i <= n then return t[i] end
	end
end

helpful_guys = {
	"buxiu", "zhang3",
	"morler", "lambda", "sunlight",
	"--------",
	"le", "flicker",
	"doy","zhang3", "Kasi",
	"\n"
}
for e in list_iter(helpful_guys) do
	print(e)
end

-- [[
-- 	D:\Note\lua\0syntax>lua print.luaf
-- 	lua: print.lua:3: attempt to call field 'getn' (a nil value)
-- 	stack traceback:
-- 	        print.lua:3: in function 'list_iter'
-- 	        print.lua:18: in main chunk
-- 	        [C]: in ?

-- 	D:\Note\lua\0syntax>
-- ]]