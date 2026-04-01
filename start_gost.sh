#!/bin/bash

# 检查 PROXY_USER 和 PROXY_PASSWORD 是否都已设置且不为空
if [[ -n "$PROXY_USER" && -n "$PROXY_PASSWORD" ]]; then
    # 如果设置了环境变量，则启动带认证的代理服务
    # 格式：协议://用户名:密码@:端口
    exec /usr/local/bin/gost -L "http://${PROXY_USER}:${PROXY_PASSWORD}@:1080"
else
    # 如果没有设置环境变量，则启动无认证的代理服务
    # 使用 http://:1080 等同于 :1080，会自动兼容 HTTP 和 SOCKS5
    exec /usr/local/bin/gost -L http://:1080
fi