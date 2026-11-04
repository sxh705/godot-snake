# 贪吃蛇 SnakeBite — Windows / Android 双端小游戏

Godot 4.7 编写的贪吃蛇，一套工程同时出 Windows exe 与 Android APK。基于
[godot-dual-starter](https://github.com/sxh705/godot-dual-starter) 模板搭建，
导出链路已实测打通。

## 玩法与操作

- 经典规则：吃食物变长加速，撞墙或撞到自己结束
- **键盘**：方向键 / WASD 转向，`R` 重开，`Esc` 返回主页
- **触屏**：在棋盘任意位置滑动转向（可连续滑动，不必抬手）
- 最佳分自动存档（`user://snake_best.cfg`），结束后一键再来一局
- 棋盘 24×14 格，吃一个食物加 10 分并小幅提速

```
start.tscn（开始页）
  ├─→ game.tscn（贪吃蛇主玩法）
  └─→ settings.tscn（音量 / 光标设置，来自模板，改动即存档）
```

## 环境

| 项目 | 版本 / 说明 |
|---|---|
| 引擎 | Godot **4.7.2-stable**（GL Compatibility 渲染器，对老安卓机友好） |
| JDK | 17+（Temurin 17 或 OpenJDK 21 均实测可用） |
| Android SDK | platform-tools / build-tools / android-36 |
| 调试签名 | `%USERPROFILE%\.android\debug.keystore`（别名 androiddebugkey，口令 android） |

工具路径不用写死：`env.cmd` 按「环境变量 > 已知安装位置 > PATH」的顺序解析
`GODOT_BIN` / `JAVA_HOME` / `ANDROID_HOME`，两套常见布局都内置了回落。

## 打开与运行

- 双击 **`启动Godot.cmd`** 打开编辑器，按 `F5` 运行；或命令行直接 `godot --path .`
- 首次克隆后先双击 **`setup.cmd`** 做一次本机配置（探测环境 + 把调试签名路径写进导出预设）

## 导出

- **Windows**：双击 `导出Windows.cmd` → `build/windows/SnakeBite.exe`（约 104 MB，5–15 秒）
- **Android**：双击 `导出Android.cmd` → `build/android/SnakeBite.apk`（约 35 MB，增量 1–2 分钟）

两个脚本都以**显式控制台窗口**执行：先打印工程路径、引擎版本、JDK / SDK / 签名库位置，
再原样输出 Godot 与 Gradle 的全部日志，结束后停在 `Press any key`，窗口不闪退。
失败时往上翻第一条 `ERROR` / `FAILURE` 即可；每次导出的结果另记一行在 `build/last-export.txt`。

可选参数：

```
导出Android.cmd /nopause      :: 跑完即退，不等人按键（自动化、CI 用）
set EXPORT_VERBOSE=1           :: 追加 Godot --verbose，日志更详细
```

手机连上后 `adb devices` 能看到设备即可直装：

```
adb install -r build/android/SnakeBite.apk
```

> 新克隆本仓库后，Android 导出前需先还原构建模板里的大文件（超 GitHub 100 MB 限制未入库）：
> 在编辑器中执行 **项目 → 安装 Android 构建模板**，或从
> `%APPDATA%\Godot\export_templates\4.7.2.stable\android_source.zip` 解压覆盖 `android/build/`。

## 与模板的差异

- `scenes/game.tscn` + `scripts/game.gd`：贪吃蛇完整玩法（约 180 行 GDScript，自绘棋盘，无额外资源依赖）
- `export_presets.cfg`：包名 `com.example.snakebite`，产品名 SnakeBite
- `icon.svg`：贪吃蛇图标
- 开始页文案、`project.godot` 工程名同步更新

## 已实测结果

- Windows：`SnakeBite.exe` 约 104 MB，无头启动正常（引擎自报 4.7.2.stable）
- Android：`SnakeBite.apk` 约 35 MB，`com.example.snakebite`，minSdk 24 / targetSdk 36，`arm64-v8a`
