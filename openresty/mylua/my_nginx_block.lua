-- #lua_package_path "/path/to/lua-resty-redis/lib/?.lua;;";

-- local demo = require("my_nginx_mysql_whiteip")
-- demo.mysqlwhiteip()

local redis = require "resty.redis"
local red = redis:new()
local my_remote_addr = ngx.var.remote_addr
local redis_ip = "127.0.0.1"
local redis_port = 6379
local redis_password = "123456"
local redis_key_ttltime = 60
local my_redis_db = 9
local CClimit = 500
local CCblocktime = 60
local my_token = my_remote_addr
local black_token = "black:" .. my_token
local access_token = "access:" .. my_token
local G_white_ip_token = "G_white_ip" .. my_token
local xiong_shared_test = ngx.shared.xiong_shared_test
local white_ip = {"112.91.82.50","112.91.82.59"}

local function is_include(value, tab)
   for k,v in ipairs(tab) do
      if v == value then
           return true
       end
    end
    return false
end

local function getip( )
    local myIP = ngx.req.get_headers()["X-Real-IP"]
    if myIP == nil then
        myIP = ngx.req.get_headers()["x_forwarded_for"]
    end
    if myIP == nil then
        myIP = ngx.var.remote_addr
    end
    return myIP
end


local my_remote_addr = getip()


red:set_timeout(1000) -- 1 sec

-- or connect to a unix domain socket file listened
-- by a redis server:
--     local ok, err = red:connect("unix:/path/to/redis.sock")

local ok, err = red:connect(redis_ip,redis_port)
 if not ok then
    ngx.say("failed to connect: ", err)
    return
 end
local res, err = red:auth(redis_password)
if not res then
  ngx.say("failed to authenticate: ", err)
  return
end
ok, err = red:select(my_redis_db)
if not ok then
    ngx.say("failed to use redis_db: ", err)
    return
end

local localmen_blackReq, err = xiong_shared_test.get(xiong_shared_test,black_token)
local localmen_G_white_ip_token, err = xiong_shared_test.get(xiong_shared_test,G_white_ip_token)

if ( localmen_blackReq and localmen_blackReq ~= nil ) then
    ngx.log(ngx.ERR, "ip accesss too much: ",my_remote_addr)
    ngx.exit(503)    
end

local blackReq,blerr = red:exists(black_token)
local accessReq,acerr = red:exists(access_token)

if ( localmen_G_white_ip_token and localmen_G_white_ip_token ~= nil ) then
-- pass
else
    if blackReq == 0 then        
        incrok, err = red:incr(access_token)
        if not ok then
            ngx.say("failed to incr xiognxiong: ", err)
            return
        end
        ttlok, err = red:ttl(access_token)
        if ( incrok == 1 or ttlok == -1 ) then
            ok, err = red:expire(access_token,redis_key_ttltime)
        end
        local times = tonumber(incrok)
        if times >= CClimit then
            succ, err, forcible = xiong_shared_test:safe_set(black_token, 1, 30)
            red:set(black_token,1)
            red:expire(black_token,CCblocktime)
            ok, err = red:del(access_token)            
            ngx.log(ngx.ERR, "ip accesss too much: ",my_remote_addr)
            if not ok then
                ngx.say("failed to del xiongxiong: ", err)
                return
            end            
            ngx.exit(503)
        end
    else
        ngx.log(ngx.ERR, "ip accesss too much: ",my_remote_addr)
        ngx.exit(503)    
    end
end    

local ok, err = red:set_keepalive(10000, 30)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
