Option Explicit

Dim args
Dim fso
Dim shell
Dim scriptDir
Dim psScript
Dim psExe
Dim mode
Dim command
Dim i

Set args = WScript.Arguments

If args.Count < 2 Then
    WScript.Quit 0
End If

mode = args.Item(0)

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "Copy-SelectedItemText.ps1")
psExe = shell.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")

command = Quote(psExe) & " -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File " & Quote(psScript) & " -Mode " & Quote(mode) & " -UseExplorerSelection"

For i = 1 To args.Count - 1
    command = command & " " & Quote(args.Item(i))
Next

shell.Run command, 0, True

Function Quote(value)
    Quote = Chr(34) & Replace(CStr(value), Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function
