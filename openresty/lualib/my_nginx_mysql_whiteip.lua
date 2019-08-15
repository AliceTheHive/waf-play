-- #lua_package_path "/path/to/lua-resty-mysql/lib/?.lua;;";

local _M = {}

function _M.mysqlwhiteip()
    local mysql = require "resty.mysql"
    local db, err = mysql:new()
    if not db then
        ngx.say("failed to instantiate mysql: ", err)
        return
    end
    local ok, err, errcode, sqlstate = db:connect{
        host = "127.0.0.1",
        port = 3306,
        database = "evlink_waf",
        user = "evlink_waf",
        password = "123456",
        charset = "utf8",
        max_packet_size = 1024 * 1024,
    }

    if not ok then
        ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
        return
    end
    db:set_timeout(60000) -- 60 sec

    local res, err, errcode, sqlstate = db:query("select ip from nginx_whiteip")
    if not res then
        ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return
    end   
    
    local xiong_shared_test = ngx.shared.xiong_shared_test
    local white_ip = {"112.91.82.50","112.91.82.59"}
    for pos,val in ipairs(res) do
        for name, value in pairs(val) do
            succ, err, forcible = xiong_shared_test:safe_set("G_white_ip"..value,value,300)
        end
    end
    local ok, err = db:set_keepalive(3600000, 6000)
    if not ok then
        ngx.log(ngx.ERR,"failed to set keepalive: ", err)
        return
    end    
end

return _M
