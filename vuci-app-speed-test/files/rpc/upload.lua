
local cURL = require("cURL")
local params = {...}

os.execute('head -c '..params[1]..' /dev/urandom > /tmp/temp.txt')

local post = cURL.form()
  :add_file  ("name", "/tmp/temp.txt", "text/plain")

local start_time = os.clock()
local end_time = os.clock()

local c = cURL.easy()
  :setopt_url(params[2])
  :setopt_httppost(post)
  :setopt_timeout(6)
  :setopt_connecttimeout(2)
  :setopt_accepttimeout_ms(2)
  :setopt_noprogress(false)
  :setopt_progressfunction(function(dltotal, dlnow, ultotal, ulnow)
    end_time = os.clock()
    local elapsed_time = end_time - start_time
    f = io.open("/tmp/speedtest_up.txt", "w")
    local up_speed = ulnow / 1000000 / elapsed_time
    -- ultotal, uploaded file size in byte
    -- ulnow, number of bytes uploaded so far
    f:write(elapsed_time, ',', ultotal, ',', ulnow, ',', up_speed, '\n')
    f:close()
    return 1
  end)

local ok, err = pcall(function() c:perform() end)
