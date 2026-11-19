# 今日待办

macOS 菜单栏待办，第一版。这是一个菜单栏附属应用（accessory / `LSUIElement`）：只出现在菜单栏，没有 Dock 图标。关闭弹窗不会退出，应用会留在菜单栏里。

数据写在本机 JSON 里，没有账号、云同步或提醒。界面锁定浅色。可以新增、勾选、取消完成、悬停删除，以及跨日把未完成项留在今天。不做改标题，也不做拖拽排序。昨天及更早完成的条目仍留在 JSON 中，今天的列表不再显示，也不会被物理删除。

最低系统：macOS 13 Ventura。

## 用 Swift 命令行工具构建和运行

只安装了 Xcode Command Line Tools（有 `swift`，没有完整 Xcode）时，在仓库根目录执行：

```bash
swift test
./scripts/package-app.sh
open dist/今日待办.app
```

- `swift test` 跑 Domain / Persistence / 跨日单元测试，不需要菜单栏。
- `./scripts/package-app.sh` 用 `swift build -c release` 打出 `dist/今日待办.app`。`dist/` 是构建产物，不提交到 git。
- 打开后菜单栏会出现单色的 `checkmark.circle`。点击打开今天的列表；再点图标、点窗口外面或按 Esc 关闭。要退出，在活动监视器中结束「今日待办」。

脚本用 ad-hoc 签名（`codesign -s -`），没有公证，也没有启用 App Sandbox（ad-hoc 签名加沙盒在 macOS 上经常无法启动）。从别的电脑拷来的包可能被 Gatekeeper 拦住；本机打包的 app 可以直接打开。未沙盒时数据在：

`~/Library/Application Support/com.hx645965603.TodayTodo/todos.json`

## 用 Xcode 打开并运行

需要 Xcode 16 或更高（Swift 6 工具链，用来编译 Swift Testing）。本仓库在只有 Command Line Tools 的机器上无法运行 `xcodebuild`。

1. 打开 `TodayTodo.xcodeproj`
2. 选择 scheme **TodayTodo**
3. 按 Run（⌘R）

Xcode 工程启用了 App Sandbox，并且 `LSUIElement = YES`，所以没有 Dock 图标，也不申请辅助功能、通知或全盘访问。沙盒运行时数据在：

`~/Library/Containers/com.hx645965603.TodayTodo/Data/Library/Application Support/com.hx645965603.TodayTodo/todos.json`

在装有完整 Xcode 的机器上跑测试：

```bash
xcodebuild test -project TodayTodo.xcodeproj -scheme TodayTodo -destination 'platform=macOS'
```

没有完整 Xcode 时用上面的 `swift test`。

测试覆盖新增、拒绝空标题、完成与取消完成、删除、保存后重新加载，以及跨日：未完成项仍出现在今天，昨天完成的项今天不显示但还在 JSON 里，今天完成的项仍然显示，包括 23:59 到 00:00 的边界。

## 工程结构

```
Sources/AppShell        入口、菜单栏、弹窗开关
Sources/TodayUI         顶栏、列表、行、空状态、添加栏
Sources/Domain          模型、排序和「今天」可见规则
Sources/Persistence     JSON 原子写入
Sources/DayRollover     监听日历日变化
```

界面只调用 Domain，不直接读写文件。跨日只刷新可见列表，不删除昨天已完成的记录。
