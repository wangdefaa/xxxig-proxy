# XXXig Proxy（无捐献 改造版）

[![License: GPL v3](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

本项目基于 [XMRig Proxy](https://github.com/xmrig/xmrig-proxy) 改造：

**彻底移除内置开发者捐献（dev-fee）**——原版默认抽取 2% 算力捐给作者矿池（在转发超过 256 个矿工时生效），本版已从源码层面删除，代理 **不再向作者钱包分流任何算力**。

XXXig Proxy 是一款极高性能的 CryptoNote stratum 协议代理（支持 Monero 等），可在仅 1024 MB 内存的廉价虚拟机上高效管理超过 10 万个连接，把矿池侧的连接数从十万级压缩到数百级。代码库与 [XMRig](https://github.com/xmrig/xmrig) 矿工共享。

## 本改造版特性

- **零捐献**：删除 `DonateStrategy` 与代理专有的 `DonateSplitter` / `DonateMapper`，清理 `donate-level` / `donate-over-proxy` 配置项、命令行选项，以及 API 的 `donate_level` / `donated` / `hashes_donate` 字段。代理转发核心不受影响。

## 兼容性

兼容任意矿池，以及任意支持 NiceHash 协议的矿工。

## 编译

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

原版编译说明见 [XMRig 官方文档](https://xmrig.com/docs/proxy)。

## 使用

推荐用 [JSON 配置文件](https://xmrig.com/docs/proxy) 配置代理，比命令行更灵活。完整命令行选项见 `./xxxig-proxy --help`。

- **代理模式**（`-m, --mode`）：`nicehash`（默认）、`simple`、`extra_nonce`。
- **绑定地址**（`-b, --bind`）：例如 `0.0.0.0:3333`。
- :boom: Linux 下若需管理 **1000 以上连接**，请先 [调高打开文件数限制](https://github.com/xmrig/xmrig-proxy/wiki/Ubuntu-setup)。

## 关于捐献

本改造版已彻底移除原版内置的开发者捐献。XMRig 是优秀的开源项目，在此向上游作者致谢；如你愿意支持上游开发，请访问其官方仓库。

## 上游与许可

- 基础项目：[XMRig Proxy](https://github.com/xmrig/xmrig-proxy)（作者 [xmrig](https://github.com/xmrig)、[sech1](https://github.com/SChernykh)）
- 许可证：[GPL-3.0](LICENSE)
