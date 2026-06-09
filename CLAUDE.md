# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

xxxig-proxy 是基于 [XMRig Proxy](https://github.com/xmrig/xmrig-proxy) 的改造版，**已从源码层面彻底移除开发者捐献（dev-fee）**。它是高性能 CryptoNote/Monero stratum 代理，把大量矿工连接聚合到少量上游矿池连接。`src/base/` 与 XMRig 矿工共享代码。

## 构建

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

- 产物：`build/xxxig-proxy`（CMake `project(xxxig-proxy)`）。
- 依赖：libuv（必需）、OpenSSL（TLS，默认开启）。
- 常用 CMake 选项：`WITH_HTTP`（HTTP API，默认 ON）、`WITH_TLS`（默认 ON）、`WITH_DEBUG_LOG`（默认 OFF）、`WITH_GOOGLE_BREAKPAD`（默认 OFF）。
- 无单元测试框架、无 CI；拼写检查用 codespell（配置见 `.codespellrc`）。
- 运行：`./xxxig-proxy -c config.json`，`./xxxig-proxy --help` 查看全部选项。

## 架构（big picture）

### 启动链路
`src/xmrig.cpp` → `App` → `core/Controller`（持有 `Config` 与 `Proxy`）。`base/kernel/Base` 负责配置加载、文件监听与热重载。

### 事件驱动核心
代理逻辑围绕发布/订阅事件展开（`proxy/Events`、`proxy/interfaces/IEventListener`）。`Proxy` 构造函数（`proxy/Proxy.cpp`）是总装配点——用 `Events::subscribe(type, listener)` 把各组件挂到事件流上。事件类型见 `proxy/interfaces/IEvent`：`Connection` / `Close` / `Login` / `Submit` / `Accept`。

典型份额流转：矿工登录 → `LoginEvent` → splitter 分配 mapper；矿工提交 → `SubmitEvent` → mapper 转发到上游；上游接受 → `AcceptEvent` → `Stats` / `ShareLog` / `Workers` 统计。

### Splitter / Mapper（转发核心）
代理有三种模式（`Config::Mode`），`Proxy` 构造时按模式选择对应 splitter（均实现 `ISplitter`）：
- `NICEHASH_MODE`（默认）→ `NonceSplitter` + `NonceMapper` + `NonceStorage`
- `SIMPLE_MODE` → `SimpleSplitter` + `SimpleMapper`
- `EXTRA_NONCE_MODE` → `ExtraNonceSplitter` + `ExtraNonceMapper` + `ExtraNonceStorage`

Splitter 管理多个 Mapper；每个 Mapper 是 `IStrategyListener`，通过 `IStrategy`（`base/net/stratum/strategies` 的 `FailoverStrategy` / `SinglePoolStrategy`，由 `Pools::createStrategy` 创建）连接上游矿池，把多个下游矿工的份额聚合到少量上游连接。`proxy/Server` 监听矿工接入，`proxy/Miner` 表示单个下游矿工连接。

### 配置系统（改动需多处同步）
新增/修改一个命令行配置项时，需同步改动以下文件，缺一则不生效：
- `base/kernel/interfaces/IConfig.h`：`Keys` 枚举（选项 ID）
- `core/config/Config_platform.h`：`option` 表（长选项名 → Key）
- `base/kernel/config/BaseTransform.cpp`：`transform*` 把命令行值写入 JSON
- `core/config/usage.h`：`--help` 文本
- `src/config.json`：默认配置

矿池相关配置在 `base/net/stratum/Pools`；proxy 专有配置（mode/bind/custom-diff/workers 等）在 `core/config/Config`。

### 代码组织
- `src/base/`：与 XMRig 矿工共享的内核（配置、stratum 网络、TLS、日志、工具），经 `src/base/base.cmake` 引入。
- `src/proxy/`：代理专有逻辑（事件、splitters、Miner、Server、Stats、ShareLog、Workers）。
- `src/core/`：`Config` 与 `Controller`。
- `src/api/v1/ApiRouter`：HTTP JSON API（summary/miners/workers）。
- `src/3rdparty/`：vendored 依赖（rapidjson、fmt、llhttp 等）。

## 改造版约定（去捐献）

- 已删除 `src/donate.h`、`net/strategies/DonateStrategy.*`、`proxy/splitters/donate/`（DonateSplitter/DonateMapper）。
- 已移除 `donate-level` / `donate-over-proxy` 配置与命令行、API 的 `donate_level` / `donated` / `hashes_donate`、`StatsData::donateHashes`。
- **新增功能时不要重新引入任何 donate 逻辑或字段。**
- `Config::hasAlgoExt()` 现直接返回 `m_algoExt`（原先依赖已删除的 `isDonateOverProxy()`）。

## 代码风格

- 沿用 XMRig 风格：文件头 GPL 注释、`xmrig` 命名空间、成员变量 `m_` 前缀、不可拷贝类用 `XMRIG_DISABLE_COPY_MOVE_DEFAULT` 宏。
- 大量使用前向声明，完整类型定义在 .cpp 中显式 `#include`。删除某个 `#include` 时注意它可能为其它类型提供了传递性的完整定义（例如各 mapper 经 `DonateStrategy.h` 间接获得 `IStrategy` 完整定义）。
