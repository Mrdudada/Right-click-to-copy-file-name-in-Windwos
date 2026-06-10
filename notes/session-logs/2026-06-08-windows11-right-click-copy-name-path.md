# Session Log：Windows 11 右键复制文件名/路径工具

日期：2026-06-08
项目目录：`D:\Project\Little Tools\windows 右键复制文件名`

## 用户目标

用户在 Windows 11 中经常需要复制一个或多个文件/文件夹的文件名或完整路径，但系统默认右键菜单没有直接提供批量复制功能。用户希望创建一个本地工具，实现：

- 选中单个或多个文件/文件夹后右键操作。
- 可批量复制文件名。
- 可批量复制完整路径。
- 支持中文、空格、特殊字符路径。
- 尽量使用方便、轻量、可安装、可卸载的方式。

## 本轮主要对话与决策

### 1. 初始需求

用户说明：

> 当前我在使用 Windows 11，我经常要复制多个或一个文件名或文件路径，但是 Windows 自带的右键菜单中并没有这个功能，我想要你帮我写一个工具实现我的目标，我选择单个或多个文件后能右键批量复制文件名或路径。

处理思路：

- 当前目录为空，按新建工具处理。
- 采用轻量方案：PowerShell 脚本 + 当前用户注册表 `HKCU\Software\Classes`。
- 不写入 `HKLM`，避免管理员权限。
- 不需要编译，便于审计和修改。
- 第一版目标是稳定可用，菜单至少出现在 Windows 11 的“显示更多选项”经典菜单中。

### 2. 计划阶段

生成并获批的计划文件：

`C:\Users\Qiuxi\.claude\plans\windows11-windows-snazzy-kitten.md`

计划中的核心方案：

- 创建 `scripts\Copy-SelectedItemText.ps1` 作为核心复制脚本。
- 创建 `install.ps1` 写入右键菜单注册表项。
- 创建 `uninstall.ps1` 删除注册表项。
- 创建 `README.md` 说明安装、卸载、使用和限制。
- 注册表路径使用：
  - `HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFileName`
  - `HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFullPath`

### 3. 第一版实现

创建了以下文件：

- `install.ps1`
- `uninstall.ps1`
- `scripts\Copy-SelectedItemText.ps1`
- `README.md`
- `.gitignore`

核心行为：

- `Copy-SelectedItemText.ps1` 支持参数：
  - `-Mode Name`：复制文件名或文件夹名。
  - `-Mode FullPath`：复制完整路径。
  - `-UseExplorerSelection`：右键菜单只传入一个触发路径时，尝试从当前资源管理器窗口读取完整选中项列表，提高多选成功率。
  - `-PassThru`：测试模式，只输出结果，不写剪贴板。
- 使用 Windows 换行 `` `r`n `` 拼接多项结果。
- 使用 `System.Windows.Forms.Clipboard` 写剪贴板，并带重试；失败时退回 `Set-Clipboard`。

验证过：

- PowerShell 脚本语法正常。
- 文件名提取对中文、空格、`[`、`]` 等字符正常。
- 完整路径输出正常。
- 安装脚本可写入注册表。
- 卸载脚本可删除注册表。
- 最终重新安装，注册表项处于已安装状态。

第一版安装后的注册表命令最初直接调用 PowerShell：

```text
"C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File "...\scripts\Copy-SelectedItemText.ps1" -Mode Name -UseExplorerSelection "%1"
```

### 4. 用户反馈：黑窗口闪现、菜单排在最上面

用户提出两个问题：

> 1. 每次复制都要闪现一下黑窗口？有没有不闪现的方法
> 2. 在经典菜单中有，但是能不能不要排在最上面，第一个应该是打开文件的，这样比较符合习惯

处理：

#### 4.1 解决黑窗口闪现

原因：资源管理器直接调用 `powershell.exe`，即使使用 `-WindowStyle Hidden`，仍可能短暂出现黑色控制台窗口。

改动：增加隐藏启动器：

`D:\Project\Little Tools\windows 右键复制文件名\scripts\Run-Hidden.vbs`

右键菜单现在调用链为：

```text
wscript.exe -> Run-Hidden.vbs -> 隐藏运行 powershell.exe -> Copy-SelectedItemText.ps1
```

`Run-Hidden.vbs` 使用：

```vbscript
shell.Run command, 0, True
```

其中窗口样式 `0` 表示隐藏窗口。

#### 4.2 调整菜单位置

原来 `install.ps1` 中设置：

```powershell
Position = Top
```

导致菜单项排在经典菜单顶部，抢占“打开”等常用操作位置。

已改为：

```powershell
Position = Bottom
```

现在菜单项会尽量排在经典右键菜单底部。

### 5. 用户询问：能否显示在 Windows 11 最新一级菜单

用户问：

> 很好，如何能不用经典菜单才显示呢，也就是在最新的一级菜单里也能显示

回答要点：

- 现在的传统注册表方式 `HKCU\Software\Classes\...\shell` 不能稳定进入 Windows 11 新版一级菜单，通常只显示在“显示更多选项”的经典菜单里。
- 若要真正进入 Windows 11 新版一级右键菜单，需要更复杂的方案。

可选方案：

1. 正规方案：写 Windows 11 Explorer Command 扩展
   - 实现 COM Shell Extension，通常涉及 `IExplorerCommand`。
   - 接收 `IShellItemArray` 以支持多选。
   - 可能需要 MSIX 或 Sparse Package 给扩展 App Identity。
   - 优点：真正进入新版一级菜单，多选稳定，不闪窗口。
   - 缺点：实现复杂，需要编译和更复杂的安装/卸载。

2. 简单但不推荐：禁用 Windows 11 新版菜单，恢复经典菜单为默认菜单
   - 这样当前工具会直接显示。
   - 但这不是“进入新版一级菜单”，而是关闭新版菜单。
   - 会影响整个系统右键菜单体验。

3. 保持现状
   - 当前脚本方案轻量、可审计、无需管理员权限。
   - 缺点是菜单一般位于“显示更多选项”中。

推荐：

- 当前脚本版适合轻量自用。
- 如果后续明确需要“真正出现在 Windows 11 新版一级菜单”，建议开发第二版：C#/.NET 或 COM Explorer Command 扩展。
- 下一步可先检查环境：

```powershell
dotnet --info
```

并确认是否可使用 Windows SDK 或 Visual Studio Build Tools。

## 当前文件状态

### `scripts\Copy-SelectedItemText.ps1`

用途：核心复制逻辑。

当前能力：

- 支持 `Name` 和 `FullPath` 两种模式。
- 支持 `-UseExplorerSelection` 从资源管理器窗口补全多选项。
- 支持 `-PassThru` 便于命令行测试。
- 写剪贴板时有重试和 fallback。

关键设计：

- 文件名提取使用 `[System.IO.Path]::GetFileName($trimmedPath)`，避免 `Split-Path -LiteralPath` 在不存在测试路径上触发解析问题。
- 路径去重使用规范化小写路径。
- 多项输出按 `` `r`n `` 拼接。

### `scripts\Run-Hidden.vbs`

用途：隐藏启动器，避免复制时闪现 PowerShell 黑窗口。

核心行为：

- 接收第一个参数作为模式：`Name` 或 `FullPath`。
- 后续参数作为路径传给 PowerShell 脚本。
- 使用 `wscript.exe` 运行，不显示控制台。
- 使用 `shell.Run command, 0, True` 隐藏 PowerShell 窗口并等待执行完成。

### `install.ps1`

用途：安装或更新右键菜单。

当前行为：

- 检查核心脚本和隐藏启动器是否存在。
- 写入当前用户注册表。
- 注册两个菜单项：
  - `复制文件名`
  - `复制完整路径`
- 设置：
  - `MUIVerb`
  - `Icon = imageres.dll,-5302`
  - `MultiSelectModel = Player`
  - `Position = Bottom`
- command 已改为调用：

```text
"%SystemRoot%\System32\wscript.exe" //nologo "...\scripts\Run-Hidden.vbs" "Name" "%1"
```

和：

```text
"%SystemRoot%\System32\wscript.exe" //nologo "...\scripts\Run-Hidden.vbs" "FullPath" "%1"
```

### `uninstall.ps1`

用途：卸载右键菜单。

当前行为：

- 删除：
  - `HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFileName`
  - `HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFullPath`
- 不删除项目文件。
- 不影响其他注册表项。

### `README.md`

用途：用户说明。

当前包含：

- 功能说明。
- 安装命令。
- 使用方法。
- 卸载命令。
- 移动目录后的处理。
- 测试核心脚本的方法。
- 已知限制。
- 说明隐藏启动器用于避免黑窗口闪现。
- 说明菜单项尽量放在经典菜单底部。

## 已执行验证

### 脚本测试

执行过类似测试：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Project\Little Tools\windows 右键复制文件名\scripts\Copy-SelectedItemText.ps1" -Mode Name -PassThru "D:\Temp\中文 文件 [1].txt" "D:\Temp\a b.txt"
```

输出：

```text
中文 文件 [1].txt
a b.txt
```

完整路径模式输出：

```text
D:\Temp\中文 文件 [1].txt
D:\Temp\a b.txt
```

### 语法验证

验证过：

- `install.ps1 syntax OK`
- `uninstall.ps1 syntax OK`
- `Copy-SelectedItemText.ps1 syntax OK`

### 隐藏启动器验证

执行过：

```powershell
cscript.exe //nologo "D:\Project\Little Tools\windows 右键复制文件名\scripts\Run-Hidden.vbs" Name "D:\Temp\中文 文件 [1].txt"
```

结果：无报错。

### 注册表验证

重新运行 `install.ps1` 后验证：

- `CopyFileName` 存在。
- `CopyFullPath` 存在。
- 默认名称分别为：
  - `复制文件名`
  - `复制完整路径`
- `Position = Bottom`
- 命令以 `wscript.exe` 开头。

最后状态：右键菜单已重新安装，使用隐藏启动器，位置在底部。

## 当前已知限制

1. Windows 11 新版一级右键菜单

当前脚本/注册表方案通常不能稳定显示在 Windows 11 新版一级菜单中，只能显示在“显示更多选项”的经典菜单中。

2. 多选兼容性

当前方案通过 `MultiSelectModel = Player` 和 `-UseExplorerSelection` 增强多选支持。普通资源管理器窗口中应较好工作，但个别场景仍可能只收到触发项。

3. 新版一级菜单的正式支持

如需真正支持 Windows 11 新版一级菜单，需要开发 Explorer Command 扩展，可能涉及：

- C#/.NET 或 C++。
- COM Shell Extension。
- `IExplorerCommand`。
- `IShellItemArray`。
- MSIX 或 Sparse Package。
- Windows SDK / Visual Studio Build Tools。

## 下次继续时建议直接输入的上下文提示

下次可以对 Claude 说：

```text
请读取并接入上下文：D:\Project\Little Tools\windows 右键复制文件名\notes\session-logs\2026-06-08-windows11-right-click-copy-name-path.md。
我想继续完善这个 Windows 11 右键复制文件名/路径工具。
```

如果要继续做“显示在 Windows 11 最新一级菜单”的版本，建议接着说：

```text
我想开发第二版，让“复制文件名”和“复制完整路径”真正显示在 Windows 11 新版一级右键菜单里。请先检查当前机器的 .NET / Windows SDK / Visual Studio Build Tools 环境，然后给出实现路线。
```

## 重要文件路径索引

- 项目根目录：`D:\Project\Little Tools\windows 右键复制文件名`
- 会话日志：`D:\Project\Little Tools\windows 右键复制文件名\notes\session-logs\2026-06-08-windows11-right-click-copy-name-path.md`
- 计划文件：`C:\Users\Qiuxi\.claude\plans\windows11-windows-snazzy-kitten.md`
- 核心脚本：`D:\Project\Little Tools\windows 右键复制文件名\scripts\Copy-SelectedItemText.ps1`
- 隐藏启动器：`D:\Project\Little Tools\windows 右键复制文件名\scripts\Run-Hidden.vbs`
- 安装脚本：`D:\Project\Little Tools\windows 右键复制文件名\install.ps1`
- 卸载脚本：`D:\Project\Little Tools\windows 右键复制文件名\uninstall.ps1`
- 说明文档：`D:\Project\Little Tools\windows 右键复制文件名\README.md`
