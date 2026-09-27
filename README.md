# DartKeyMux

> 基于 Flutter 的节奏游戏（音游）扩展输入设备应用 —— 用触摸屏替代键盘按键，通过 USB 数据线连接实现超低延迟输入。

[![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart)](https://dart.dev)
[![gRPC](https://img.shields.io/badge/gRPC-protocol-2ca5e0)](https://grpc.io)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

---

## 目录

- [项目概述](#项目概述)
- [系统架构](#系统架构)
- [功能特性](#功能特性)
- [快速开始](#快速开始)
  - [环境要求](#环境要求)
  - [构建与安装](#构建与安装)
  - [连接后端](#连接后端)
- [项目结构](#项目结构)
- [核心模块说明](#核心模块说明)
  - [gRPC 通信层](#grpc-通信层)
  - [模板系统](#模板系统)
  - [模板编辑器](#模板编辑器)
  - [游玩模式](#游玩模式)
- [模板分享格式](#模板分享格式)
- [自启动功能](#自启动功能)
- [后续规划](#后续规划)
- [许可证](#许可证)

---

## 项目概述

**DartKeyMux** 是一个节奏游戏外设应用，运行在通过 **USB 数据线** 连接到电脑的 Android 设备上。它利用触摸屏模拟键盘按键输入，为音游玩家提供自定义布局的软键盘替代方案。

### 为什么需要 USB 数据线？

> ⚠️ **本项目强制要求通过 USB 数据线（ADB）连接设备**。

无线网络（Wi-Fi）引入的延迟在音游场景中不可接受。通过 USB 数据线建立 ADB 反向端口转发，可以将触摸-按键的端到端延迟控制在极低水平，满足高难度音游的实时性要求。

### 工作原理

```
┌──────────────┐    USB/ADB     ┌──────────────┐    gRPC (stream)    ┌──────────────┐
│  Android 设备  │ ←──────────→ │  电脑 (后端)   │ ←───────────────→ │   游戏窗口    │
│  (Flutter App) │  端口转发     │  (Go Server)  │   模拟键盘输入      │  (如 osu!)   │
└──────────────┘                └──────────────┘                     └──────────────┘
```

1. **Flutter 前端**（本应用）：在 Android 设备上渲染可自定义的触摸按键布局，捕获多点触控事件。
2. **gRPC 双向流**：将按键事件（按下/松开）通过 gRPC 客户端流实时发送至后端。
3. **Go 后端**（独立项目）：接收按键事件，在电脑上模拟真实键盘输入，注入到游戏窗口。

> 当前版本仅支持**键盘输入模拟**，后续计划加入**鼠标输入替代**功能。

---

## 系统架构

```
flutter_application_1/
├── lib/
│   ├── main.dart                          # 应用入口，初始化 gRPC 连接与模板加载
│   ├── function_area/
│   │   ├── services/
│   │   │   ├── connect_grc.dart           # gRPC 客户端（单例）：流式会话管理 + 健康监测
│   │   │   ├── template_service.dart      # 模板 CRUD + SharedPreferences 持久化
│   │   │   └── template_codec.dart        # 模板导入/导出编解码（GKT1. 分享码）
│   │   ├── home_page_view/
│   │   │   └── choose_template.dart       # 主页：模板列表展示与操作
│   │   ├── sidebar/
│   │   │   └── main_sidebar_menu.dart     # 侧边栏：主页/自启动开关/设置入口
│   │   ├── floating_window/
│   │   │   ├── float_button.dart          # 悬浮按钮：新建 / 导入模板
│   │   │   ├── create_template_page.dart  # 模板编辑器（全屏画布 + 吸附引擎）
│   │   │   └── import_dialog.dart         # 导入模板对话框
│   │   ├── setting/
│   │   │   └── basic_setting_page.dart    # 设置页（预留）
│   │   └── all_template/
│   │       ├── base/
│   │       │   ├── template_document.dart # 模板文档数据模型
│   │       │   ├── key_widget.dart        # 按键组件数据模型（归一化坐标）
│   │       │   ├── key_widget_view.dart   # 按键组件渲染（编辑/游玩共用）
│   │       │   ├── basic_template.dart    # 基础全屏点击层
│   │       │   ├── rhythm_tap_template.dart # 节奏点击模板抽象基类
│   │       │   └── tap_zone.dart          # 分屏点击区（左右分区）
│   │       ├── system_template/
│   │       │   └── two_side_template.dart # 双区系统模板
│   │       ├── custom_template/
│   │       │   ├── editor_canvas.dart     # 编辑画布（网格 + 选中框 + 吸附线）
│   │       │   ├── property_panel.dart    # 组件属性面板（底部弹层）
│   │       │   └── snap_engine.dart       # 吸附引擎（边/中心/屏幕中线对齐）
│   │       └── player_template/
│   │           └── custom_play_page.dart  # 自定义模板游玩页（旋转感知命中）
│   ├── proto/
│   │   ├── keymux.proto                   # 按键服务 Proto 定义
│   │   └── health.proto                   # gRPC 标准健康检查 Proto
│   └── src/generated/                    # protobuf 生成的 Dart 代码
│       ├── keymux.pb.dart
│       ├── keymux.pbenum.dart
│       ├── keymux.pbgrpc.dart
│       ├── keymux.pbjson.dart
│       ├── health.pb.dart
│       ├── health.pbenum.dart
│       ├── health.pbgrpc.dart
│       └── health.pbjson.dart
├── pubspec.yaml                           # 依赖声明
├── analysis_options.yaml                  # Lint 规则
└── README.md
```

---

## 功能特性

### 核心功能

- ✅ **自定义模板编辑**：拖拽创建方形/圆形按键，自由调整位置、大小、旋转角度、颜色
- ✅ **吸附引擎**：编辑器内移动组件时自动吸附对齐（边/中心/屏幕中线），缩放时吸附他人边距
- ✅ **归一化坐标系统**：所有几何量以屏幕比例存储，同一模板在不同分辨率设备上保持一致布局
- ✅ **旋转感知命中检测**：支持旋转组件的精确点击判定（逆旋转到本地坐标系），非简单 AABB
- ✅ **多点触控**：多指同时按下不同按键，每指独立绑定按键，滑出后抬手仍释放原键
- ✅ **gRPC 双向流**：实时传输按键事件，低开销、低延迟
- ✅ **后端健康监测**：每 3 秒健康检查，连续 3 次失败判定失联，AppBar 红/绿指示灯
- ✅ **模板分享**：GKT1. 前缀 + base64(gzip(json)) 紧凑分享码，可直接粘贴导入
- ✅ **自启动**：指定模板在应用启动时自动跳转进入游玩页
- ✅ **会话生命周期保护**：防止快速进出页面导致的 gRPC 会话悬挂和内存泄漏
- ✅ **退出补发 keyUp**：页面退出时自动为所有仍处于按下状态的按键补发松开事件

### 后端依赖（Go 服务）

本项目**仅包含 Flutter 前端**。需要配套的 Go 后端服务才能完成按键注入，后端需实现：

- `rpcKeyService.keyService`（客户端流式 RPC）：接收 `stream keyInput`，返回汇总 `keyReturn`
- 标准 gRPC Health Check 服务：`grpc.health.v1.Health/Check`

---

## 快速开始

### 环境要求

| 组件 | 版本要求 |
|------|----------|
| Flutter SDK | ≥ 3.13.3 |
| Dart SDK | ≥ 3.13.3 |
| Android SDK | API 21+ (Android 5.0+) |
| Go（后端） | ≥ 1.21 |
| ADB（Android Debug Bridge） | 任意版本 |

### 构建与安装

```bash
# 1. 克隆仓库
git clone <your-repo-url>
cd DartKeyMux/flutter_application_1

# 2. 安装依赖
flutter pub get

# 3. 生成 protobuf Dart 代码（如已修改 .proto 文件）
# 需要安装 protoc 和 protoc-gen-dart 插件
protoc --dart_out=lib/src/generated \
       -Ilib/proto \
       lib/proto/keymux.proto lib/proto/health.proto

# 4. 构建 APK（Release 模式以获得最佳性能）
flutter build apk --release

# 5. 安装到设备
flutter install
```

### 连接后端

```bash
# 1. 通过 USB 连接你的 Android 设备
# 2. 建立 ADB 反向端口转发（将设备上的 50051 转发到电脑）
adb reverse tcp:50051 tcp:50051

# 3. 启动 Go 后端服务（确保监听 0.0.0.0:50051）

# 4. 手机上打开 DartKeyMux 应用
#    AppBar 右侧指示灯变绿 = 连接成功
```

> 📌 **修改后端地址**：编辑 `lib/main.dart` 第 14-17 行，修改 `host` 和 `port` 参数。

---

## 核心模块说明

### gRPC 通信层

文件：`lib/function_area/services/connect_grc.dart`

| 特性 | 实现 |
|------|------|
| 连接模式 | 非安全通道（`ChannelCredentials.insecure()`），仅用于本地 USB 转发 |
| 按键传输 | 客户端流式 RPC（`keyService`），持续发送 `keyInput` 消息 |
| 会话管理 | `startSession()` 建立流 → `sendKey()` 推入按键 → `endSession()` 关闭流并等待汇总 |
| 会话隔离 | `_sessionToken` 递增令牌，防止旧会话回调污染新会话状态 |
| 超时保护 | 关流 2s 超时 + 等待返回 3s 超时，防止连接挂死时的永久悬挂 |
| 健康监测 | 每 3s 调用 Health/Check，连续 3 次失败才判定未连接（防抖） |
| 连接指示灯 | `ValueNotifier<bool> isBackendAlive`，驱动 AppBar 红/绿状态显示 |

### 模板系统

文件：`lib/function_area/services/template_service.dart`

使用 `ChangeNotifier` 模式，任何监听者都能响应模板变更：

- **持久化**：通过 `SharedPreferences` 以 JSON 字符串列表存储
- **解析兼容**：`draftAt()` 对旧版纯文本存档做兜底处理，避免 build 期崩溃
- **版本标记**：模板 JSON 带有 `'v': 1` 版本号，为未来格式升级预留空间

### 模板编辑器

文件：`lib/function_area/floating_window/create_template_page.dart`

- 全屏画布 + 网格背景 + 播放区边界虚线
- 支持方形 / 圆形两种形状的按键组件
- 拖拽移动（带吸附线）、旋转（45° 步进吸附）、缩放（边对齐吸附）
- 层级调整：置顶 / 上移 / 下移 / 置底
- 复制 / 删除组件
- 属性面板：映射按键、形状、大小、旋转、颜色（松开/按下双色）

### 游玩模式

文件：`lib/function_area/all_template/player_template/custom_play_page.dart`

- 全屏触摸监听，从最上层组件开始做旋转感知命中
- 多点触控：每指独立绑定一个按键组件
- 指针绑定语义：按下后滑出组件，抬手仍释放同一个键（模拟真实琴键手感）
- 页面退出时自动补发所有未松开的 keyUp 事件

---

## 模板分享格式

分享码格式：

```
GKT1.<base64url(gzip(UTF-8 JSON))>
```

- `GKT1.` — 版本前缀（GoKeyMux Template v1）
- 后续为模板 JSON 的 gzip 压缩 + base64url 编码
- 解码后为含 `name`、`v`（版本号）、`ws`（组件列表）的 JSON 对象
- 所有几何量均为归一化坐标（屏幕比例），跨分辨率兼容

导入时也接受纯 JSON（不以 `GKT1.` 开头但以 `{` 开头的字符串），方便高级用户手动编辑。

---

## 自启动功能

在某个模板上点击闪电按钮可将其设为「自启动模板」。开启侧边栏的「自启动指定模板」总开关后，应用启动时会自动跳过主页并直接进入该模板的游玩模式。

- 同一模板再次点击闪电按钮 = 取消自启动
- 不同模板点击 = 转移自启动属性
- 删除已设为自启动的模板时，自启动自动取消

---

## 后续规划

- [ ] 鼠标输入替代功能
- [ ] 更多系统预设模板（四区、六区、环形布局等）
- [ ] 设置页面功能实现（后端地址配置 UI、主题切换等）
- [ ] iOS 平台支持评估（需要 MFI 或 HID 替代方案）
- [ ] 多后端地址管理与一键切换
- [ ] 按键宏录制与回放

---

## 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](./LICENSE) 文件。

---

*Made with Flutter ❤️ for rhythm game enthusiasts.*
