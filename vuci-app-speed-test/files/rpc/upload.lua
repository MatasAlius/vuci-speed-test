
local cURL = require("cURL")
local params = {...}

f = io.open("/tmp/speedtest_up.txt", "w")
f:write('0,0,0,0,0\n')
f:flush()

os.execute('head -c '..params[1]..' /dev/urandom > /tmp/temp.txt')

local post = cURL.form()
  :add_file  ("name", "/tmp/temp.txt", "text/plain")

local start_time = os.clock()
local end_time = os.clock()

local c = cURL.easy()
  :setopt_url(params[2])
  :setopt_httppost(post)
  :setopt_timeout(10)
  :setopt_connecttimeout(2)
  :setopt_accepttimeout_ms(2)
  :setopt_noprogress(false)
  :setopt_progressfunction(function(dltotal, dlnow, ultotal, ulnow)
    end_time = os.clock()
    local elapsed_time = end_time - start_time
    local up_speed = ulnow / 1000000 / elapsed_time * 8
    f:seek("set") 
    f:write(elapsed_time, ',', ultotal, ',', ulnow, ',', up_speed, ',0', '\n')
    f:flush()
    return 1
  end)

local ok, err = pcall(function() c:perform() end)
os.execute('sleep 1')
f:seek("set") 
f:write('-1,-1,-1,-1,1\n')
f:flush()
f:close()
os.execute('rm /tmp/temp.txt')