
local cURL = require("cURL")
local params = {...}

os.execute('head -c '..params[1]..' /dev/urandom > temp.txt')
local post = cURL.form()
  :add_file  ("name", "temp.txt", "text/plain")

f = io.open("/tmp/speedtest_connect_"..params[3]..".txt", "a+")
f:flush()

local response = -1
local connect = -1
local total = -1
local c = cURL.easy()
  :setopt_url(params[2])
  :setopt_httppost(post)
  :setopt_timeout(3)
  :setopt_connecttimeout(2)
  :setopt_accepttimeout_ms(2)

local ok, err = pcall(function() c:perform() end)
response = c:getinfo_response_code()
if ok then
  if response == 200 then
    connect = c:getinfo_connect_time()
    total = c:getinfo_total_time()
    upload = c:getinfo_speed_upload()
  else
    ok = false
  end
end
c:close()
print(params[3], ok, response, connect, total)
f:write(params[3], ',', tostring(ok), ',', response, ',', connect, ',', total, '\n')
f:flush()
f:close()