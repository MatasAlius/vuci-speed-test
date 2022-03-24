
local cURL = require("cURL")
local params = {...}

f = io.open("/tmp/speedtest_down.txt", "w")
f:write('0,0,0,0,0\n')
f:flush()

local start_time = os.clock()
local end_time = os.clock()

local c = cURL.easy()
  :setopt_url(params[1])
  :setopt_useragent('Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)')
  :setopt_timeout(10)
  :setopt_connecttimeout(2)
  :setopt_accepttimeout_ms(2)
  :setopt_noprogress(false)
  :setopt_progressfunction(function(dltotal, dlnow, ultotal, ulnow)
    end_time = os.clock()
    local elapsed_time = end_time - start_time
    local down_speed = dlnow / 1000000 / elapsed_time * 8
    f:seek("set") 
    f:write(elapsed_time, ',', dltotal, ',', dlnow, ',', down_speed, ',0', '\n')
    f:flush()
    return 1
  end)

local ok, err = pcall(function() c:perform() end)
os.execute('sleep 1')
f:seek("set") 
f:write('-1,-1,-1,-1,1\n')
f:flush()
f:close()
