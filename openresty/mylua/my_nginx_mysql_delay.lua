local delay = 180
local handler
handler = function (premature)
-- do some routine job in Lua just like a cron job
    if not premature then
        local demo = require("my_nginx_mysql_whiteip")
        demo.mysqlwhiteip()
--        ngx.log(ngx.ERR, "xiongxiong test mm test")
    end
end

if 0 == ngx.worker.id() then
    local ok, err = ngx.timer.every(delay, handler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end