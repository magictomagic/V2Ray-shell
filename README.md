# V2Ray-shell

##### 向 [atrandys](www.atrandys.com) 致敬

#### 目前只在 vultr 的 CentOs 7 上试过，推荐使用 CentOS 7 系统

> 原脚本(出自 [atrandys](www.atrandys.com))

```shell
curl -O https://raw.githubusercontent.com/atrandys/v2ray-ws-tls/master/v2ray_ws_tls.sh && chmod +x v2ray_ws_tls.sh && ./v2ray_ws_tls.sh
```

> ### 改动与优化
>
> > #### 添加对时（亚洲/上海）
> >
> > #### 将 nginx 服务添加至 systemctl
> >
> > #### 解决域名输入错误无法修改问题（以参数形式输入）

## 用法

获得脚本并添加权限

```shell
curl -O https://raw.githubusercontent.com/magictomagic/V2Ray-shell/master/mtm-v1.sh && chmod +x mtm-v1.sh 
```

配置【你解析好的域名】，添加伪装

```shell
./mtm-v1.sh -d [你解析好的域名]
```

将 nginx 添加至 systemctl (可选。若不选，输入 systemctl status nginx 会显示 failed，但问题不大)

```shell
./mtm-v1.sh -a
```

查看 nginx 与 v2ray 状态

```SHELL
./mtm-v1.sh -s
```

其它参数信息

```shell
 -d [domain]            install v2ray+ws+tls
 -a                     add nginx to systemctls
 -s                     check the status of nginx and v2ray
 -u                     upgrade v2ray
 -r                     remove v2ray
 -n                     remove nginx
 -h                     help
```

后续待完善与探索

> ##### 多几个伪装的网站页面，规避特征
>
> ##### 使用最新的操作系统（目前 CentOs 8），最新的协议（目前 tls 1.3）
>
> 将脚本依赖的源放入自己 github 与硬盘中，以备不时之需
>
> 整合 bbr 加速脚本，配置更方便(CentOs 8 自带)
>
> 新翻墙方法 [Trojan](https://fanqiang.network/105441.html)、[一键脚本](https://www.atrandys.com/2019/2154.html)、[相关教程1](http://program-thinker.blogspot.com/2018/10/trojandebian.html)、[教程2](https://dafahao.com/trojan-caddy.html)、[教程3]([http://luyiminggonnabeok.cn/2019/12/07/%E4%B8%80%E9%94%AE%E8%84%9A%E6%9C%AC%E6%90%AD%E5%BB%BATrojan%E6%A2%AF%E5%AD%90%E8%AF%A6%E7%BB%86%E6%95%99%E7%A8%8B/](http://luyiminggonnabeok.cn/2019/12/07/一键脚本搭建Trojan梯子详细教程/))
>
> 



