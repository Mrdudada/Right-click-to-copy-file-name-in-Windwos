# Windows 11 右键复制文件名/路径

一个轻量的 Windows 11 小工具，用于在资源管理器中选中单个或多个文件、文件夹后，通过右键菜单批量复制文件名或完整路径。

## 功能

安装后会添加两个右键菜单项：

- 复制文件名
- 复制完整路径

复制多个项目时，每个项目占一行。

示例：

```text
a.txt
b.txt
中文 文件 [1].docx
```

## 文件说明

```text
install.ps1                         安装右键菜单
uninstall.ps1                       卸载右键菜单
scripts\Copy-SelectedItemText.ps1   核心复制脚本
scripts\Run-Hidden.vbs              隐藏启动器，用于避免复制时闪现黑窗口
```

## 安装

在当前目录打开 PowerShell，运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1
```

安装只写入当前用户注册表：

```text
HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFileName
HKCU\Software\Classes\AllFilesystemObjects\shell\CopyFullPath
```

不需要管理员权限，不会修改系统执行策略。

安装后的右键菜单通过隐藏启动器运行 PowerShell，正常复制时不会再闪现黑色控制台窗口。菜单项会尽量放在经典右键菜单的底部，避免覆盖“打开”等常用操作的位置。

## 使用

1. 在资源管理器中选中一个或多个文件、文件夹。
2. 右键点击所选项目。
3. 选择“复制文件名”或“复制完整路径”。
4. 到记事本、Word、Excel、聊天窗口等位置粘贴。

在 Windows 11 中，如果首层右键菜单没有看到菜单项，请点击“显示更多选项”，或按 `Shift + F10` 打开经典右键菜单。

## 卸载

在当前目录打开 PowerShell，运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\uninstall.ps1
```

卸载脚本只删除本工具创建的右键菜单注册表项，不删除你的文件。

## 移动目录后的处理

安装脚本会把当前工具目录的绝对路径写入注册表。因此，安装后请不要直接移动本目录。

如果移动了目录，请在新位置重新运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1
```

## 测试核心脚本

不写入剪贴板，仅查看输出：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Copy-SelectedItemText.ps1 -Mode Name -PassThru "D:\Temp\中文 文件 [1].txt" "D:\Temp\a b.txt"
```

预期输出：

```text
中文 文件 [1].txt
a b.txt
```

测试完整路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Copy-SelectedItemText.ps1 -Mode FullPath -PassThru "D:\Temp\中文 文件 [1].txt" "D:\Temp\a b.txt"
```

## 已知限制

- Windows 11 的新版右键菜单对传统注册表菜单支持有限，菜单项可能出现在“显示更多选项”中。
- 本工具通过传统 shell 菜单和资源管理器当前选择项获取多选路径。普通资源管理器窗口中的多选通常可以正常工作；如果在个别场景中只复制到一个项目，请优先在“显示更多选项”中重试。
- 如果你需要菜单项稳定显示在 Windows 11 首层新版右键菜单中，需要更复杂的 Explorer 扩展或打包应用方案，超出了本轻量脚本工具的范围。
