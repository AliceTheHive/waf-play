# waf-play
openresty lua nginx

通过定时任务读取数据库里面的白名单到nginx内存里面，流程判断优先走内存控制。
计算器使用redis实现，作为多个nginx的共享信息。
超过访问数的地址，会保存一份黑名单到redis里面，作为多个nginx的共享信息。