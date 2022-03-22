
local cURL = require("cURL")
local params = {...}

local start_time = os.clock()
local end_time = os.clock()

local c = cURL.easy()
  :setopt_url(params[1])
  :setopt_timeout(6)
  :setopt_connecttimeout(2)
  :setopt_accepttimeout_ms(2)
  :setopt_noprogress(false)
  :setopt_progressfunction(function(dltotal, dlnow, ultotal, ulnow)
    end_time = os.clock()
    local elapsed_time = end_time - start_time
    f = io.open("/tmp/speedtest_down.txt", "w")
    local down_speed = dlnow / 1000000 / elapsed_time
    -- dltotal, downloaded file size in bytes
    -- dlnow, number of bytes downloaded so far
    f:write(elapsed_time, ',', dltotal, ',', dlnow, ',', down_speed, '\n')
    f:close()
    return 1
  end)

local ok, err = pcall(function() c:perform() end)
