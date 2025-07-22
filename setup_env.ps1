function BootstrapEnv {
    $WorkDir = Split-Path -Path $Script:MyInvocation.MyCommand.Path -Parent
    # $WorkDir = Split-Path $MyInvocation.MyCommand.Path

    Write-Host ">> Cleaning up environment"
    Remove-Item "$WorkDir\out" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$WorkDir\.venv" -Recurse -ErrorAction SilentlyContinue

    if (Test-Path "$WorkDir\.vscode") {
        $DotCodeFolderNonLinkFileCount = (Get-ChildItem "$WorkDir\.vscode" -File | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint) } | Measure-Object).Count
        if ($DotCodeFolderNonLinkFileCount -ne 0) {
            Write-Host "It seems like there are files that are directly added to the virtual folder. Not proceeding."
            Get-ChildItem "$WorkDir\.vscode" -File
            return 1
        }
        Remove-Item "$WorkDir\.vscode" -Recurse -ErrorAction SilentlyContinue
    }

    Write-Host ">> Symlinking vscode settings"
    New-Item -ItemType Directory -Path "$WorkDir\.vscode" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "$WorkDir\.vscode\launch.json" -Value "$WorkDir\vscode\dotFiles_launch.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "$WorkDir\.vscode\settings.json" -Value "$WorkDir\vscode\dotFiles_settings.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "$WorkDir\.vscode\extensions.json" -Value "$WorkDir\vscode\dotFiles_extensions.json" -Force | Out-Null

    Write-Host ">> Launching workspace 'code $WorkDir'"
    code $WorkDir
}

BootstrapEnv
