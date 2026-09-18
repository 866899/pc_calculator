# PC Calculator

一款 Material Design 3 风格的桌面计算器，基于 Flutter 开发，支持 Linux / Windows / macOS。

## 功能特性

- **标准 / 科学双模式**：四则运算、幂 `^`、百分号 `%`、括号、隐式乘法、科学计数法
- **数学函数**：`sin` `cos` `tan` `asin` `acos` `atan` `ln` `log` `sqrt` `abs` `exp`，支持角度制 / 弧度制切换
- **常量**：`π` / `e`
- **历史记录侧栏**：点击历史条目可复用结果
- **完整键盘支持**：数字、运算符、`Enter`（等号）、`Backspace`（退格）、`Esc`（清空）等快捷键
- **MD3 动态取色**：跟随系统主题（亮色 / 暗色）

### 键盘快捷键

| 按键 | 功能 | 按键 | 功能 |
|------|------|------|------|
| `0-9` `.` | 数字与小数点 | `Enter` / `=` | 计算（等号） |
| `+ - * / ^ %` | 四则运算、幂、百分号 | `Backspace` | 退格 |
| `x` / `X` | 乘号 | `Esc` / `Delete` | 清空 |
| `( )` | 括号 | `s` `o` `t` | sin( cos( tan( |
| `S` `O` `T` | asin( acos( atan( | `l` `g` `q` | ln( log( sqrt( |
| `e` `E` | 自然常数 e / exp( | `p` | π |

点击界面任意位置或从其他窗口切回后，键盘输入始终保持可用。

## 运行与构建

```bash
# 安装依赖
flutter pub get

# 运行测试（119 个）
flutter test

# 本地运行
flutter run -d linux          # Linux
flutter run -d windows        # Windows

# Release 构建
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## 构建 Windows EXE

Flutter 的 Windows 桌面应用**只能在 Windows 主机上构建**（需要 Visual Studio 2022 含 C++ 桌面开发工作负载）：

```powershell
flutter build windows --release
# 产物位置：build\windows\x64\runner\Release\pc_calculator.exe（整个文件夹需一起分发）
```

### 云端自动构建（推荐）

项目已内置 GitHub Actions 工作流（`.github/workflows/build-windows.yml`）：

1. 推送到 `main` 分支或手动触发（Actions → Build Windows EXE → Run workflow）
2. 构建完成后在 Actions 页面下载 `pc_calculator-windows-x64` 产物（ZIP 包）
3. 打 `v*` 标签（如 `v1.0.0`）会自动创建 Release 并附带 exe

## 项目结构

```
lib/
├── main.dart                       # 入口（桌面窗口初始化）
├── app.dart                        # 应用根（主题配置）
├── models/calculator_engine.dart   # 计算引擎（递归下降解析器）
├── state/calculator_controller.dart# 状态控制器
└── widgets/                        # MD3 界面组件
    ├── calculator_page.dart        # 主页面（模式/主题管理）
    ├── display_panel.dart          # 表达式与结果显示
    ├── keypad.dart                 # 标准/科学键盘
    ├── calculator_key.dart         # 按键组件
    └── history_panel.dart          # 历史记录侧栏
```
