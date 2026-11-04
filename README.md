# 贪吃蛇 SnakeBite — Windows / Android 双端小游戏

Godot 4.7 编写的贪吃蛇，一套工程同时出 Windows exe 与 Android APK。基于
[godot-dual-starter](https://github.com/sxh705/godot-dual-starter) 模板搭建，
导出链路已实测打通。

## 玩法与操作

- 经典规则：吃食物变长加速，撞墙或撞到自己结束
- **键盘**：方向键 / WASD 转向，`R` 重开，`Esc` 返回主页
- **触屏**：右下角方向键（仅触屏设备显示），也可在棋盘任意位置滑动转向（可连续滑动，不必抬手）
- **强化**：开局先选一项，之后每吃 5 个食物再选一次（三选一），详见 [docs/玩法说明.md](docs/玩法说明.md)
- 最佳分自动存档（`user://snake_best.cfg`），结束后一键再来一局
- 棋盘 24×14 格，吃一个食物加 10 分并小幅提速

| 强化 | 上限 | 效果 |
|---|---|---|
| 护盾 | 3 层 | 抵挡一次致命撞击，抵消后停顿 0.8 秒供转向 |
| 穿墙 | 1 层 | 撞墙从对面穿出 |
| 双倍分 | 3 层 | 每个食物多 10 分 |
| 疾行 | 3 层 | 移速提升，每个食物额外 +5 分 |
| 缓行 | 2 层 | 移速下降，操作更从容 |
| 分数 +50 | — | 立即加 50 分，不占强化位（其余满级时的兜底） |

```
start.tscn（开始页）
  ├─→ game.tscn（贪吃蛇主玩法 + 强化系统）
  └─→ settings.tscn（音量 / 光标设置，来自模板，改动即存档）
```

## 自检

```
godot --headless --path . tests/smoke.tscn --quit-after 200
```

覆盖开局强化、每 5 个食物触发、穿墙、护盾消耗与停顿、死亡判定，输出 `SMOKE PASS` 即通过。

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

## 发布（CI 自动构建）

`.github/workflows/release.yml` 在 GitHub Actions 上自动出双端包：

- **打标签即发布**：`git tag v0.1.0 && git push origin v0.1.0` → 自动在 ubuntu-latest 上
  下载 Godot 4.7.2 引擎与导出模板，导出 Windows（release）与 Android（debug 签名），
  并创建 GitHub Release 挂上 `SnakeBite-Windows.zip` 与 `SnakeBite.apk`
- **手动触发**：Actions 页面 run workflow（或 `gh workflow run release.yml`）→ 只产出 artifact 不发版，用于调试
- CI 内的 Android 签名是每次构建现生成的临时调试密钥，不使用任何真实密钥；正式签名请在本地导出
- 本机导出与 CI 导出互不影响：`export_presets.cfg` 的签名路径由 `setup.cmd` 按机器写入，
  CI 用 `sed` 现场替换，仓库中的空值不携带任何机器信息

## 与模板的差异

- `scenes/game.tscn` + `scripts/game.gd`：贪吃蛇完整玩法 + 强化系统（自绘棋盘，无额外资源依赖），触屏方向键 + 滑动双输入
- `tests/`：无头自检场景，覆盖强化节奏与碰撞规则
- `docs/玩法说明.md`：规则、计分公式、强化表与上手建议
- `project.godot`：手机端 `orientation=4`（sensorLandscape，横屏双方向跟随）
- `android/build/gradle.properties`：`org.gradle.daemon=false`——Gradle 守护进程会继承导出输出管道，
  Godot 等不到 EOF 就永不返回（表现为 APK 已生成但导出卡住不退出），禁用后构建约 50 秒且干净退出
- `export_presets.cfg`：包名 `com.example.snakebite`，产品名 SnakeBite
- `icon.svg`：贪吃蛇图标
- 开始页文案、`project.godot` 工程名同步更新

## 已实测结果

- Windows：`SnakeBite.exe` 约 104 MB，无头启动正常（引擎自报 4.7.2.stable）
- Android：`SnakeBite.apk` 约 35 MB，`com.example.snakebite`，minSdk 24 / targetSdk 36，`arm64-v8a`
