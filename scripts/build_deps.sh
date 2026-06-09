#!/bin/sh -e

# proxy 只链接 OpenSSL 与 libuv（无 hwloc，与矿工不同）
./build.uv.sh
./build.openssl3.sh
