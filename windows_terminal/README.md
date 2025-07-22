```sh
jsonnet windows_terminal/settings.jsonnet > out/settings.json
cp out/settings.json $WIN_USERPROFILE/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json
```