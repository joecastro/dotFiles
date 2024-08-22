local color_defs = import '../shell/color_definitions.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local PeacockColor(name, color) = {
    'name': name,
    'value': color.hexcolor,
};

local editorSettings = {
    "editor.fontFamily": "Cascadia Code NF, Consolas",
    "editor.fontLigatures": true,
    "editor.formatOnType": true,
    "editor.renderWhitespace": "all",
    "editor.rulers": [
        120
    ],
};
local terminalSettings = {
    "terminal.external.osxExec": "iTerm.app",
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.defaultProfile.osx": "zsh",
    "terminal.integrated.enableImages": true,
    "terminal.integrated.fontFamily": "",
    "terminal.integrated.profiles.linux": {
        "bash": {
            "icon": "terminal-bash",
            "path": "bash"
        },
        "zsh": {
            "path": "zsh"
        }
    },
    "terminal.integrated.profiles.osx": {
        "JavaScript Debug Terminal": null,
        "bash": {
            "icon": "terminal-bash",
            "path": "/opt/homebrew/bin/bash"
        },
        "pwsh": null,
        "zsh": {
            "icon": "terminal",
            "path": "/opt/homebrew/bin/zsh"
        }
    },
    "terminal.integrated.scrollback": 10000,
};
local javaSettings = {
    "java.help.showReleaseNotes": false,
    "java.imports.gradle.wrapper.checksums": [
        {
            "allowed": true,
            "sha256": "e2b82129ab64751fd40437007bd2f7f2afb3c6e41a9198e628650b22d5824a14"
        }
    ],
    "redhat.telemetry.enabled": false,
};
local vimSettings = {
    'vim.useCtrlKeys': false,
};

{
    "[java][kotlin]": {
        "editor.rulers": [
            80,
            100
        ]
    },
    "[json][jsonc]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "accessibility.dimUnfocused.enabled": true,
    "accessibility.dimUnfocused.opacity": 0.8,
    "background.windowBackgrounds": [],
    "cmake.configureOnOpen": false,
    "cmake.showOptionsMovedNotification": false,
    "diffEditor.codeLens": true,
    "diffEditor.renderSideBySide": false,
    "files.associations": {
        "vimrc": "viml"
    },
    "files.exclude": {
        "**/.classpath": true,
        "**/.factorypath": true,
        "**/.project": true,
        "**/.settings": true
    },
    "files.trimTrailingWhitespace": true,
    "git.autofetch": true,
    "git.openRepositoryInParentFolders": "always",
    "github.copilot.editor.enableAutoCompletions": true,
    "js/ts.implicitProjectConfig.checkJs": true,
    "peacock.favoriteColors": [PeacockColor(c.key, c.value) for c in std.objectKeysValues(color_defs.PeacockColors)],
    "typescript.enablePromptUseWorkspaceTsdk": true,
    "window.zoomLevel": 1,
    "workbench.editor.closeOnFileDelete": true,
    "workbench.editor.tabActionLocation": if apply_configs.host.is_osx then 'left' else 'right',
    "workbench.iconTheme": "a-file-icon-vscode",
    "workbench.productIconTheme": "feather-vscode",
    "workbench.settings.editor": "json",
    "workbench.startupEditor": "none",
    "update.mode": "none",
}
    + editorSettings
    + terminalSettings
    + javaSettings
    + vimSettings