local color_defs = import '../shell/color_definitions.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local PeacockColor(name, color) = {
    'name': name,
    'value': color.hexcolor,
};

local preferred_font_families = if apply_configs.host.is_macos
    then "CascaydiaCove Nerd Font Mono, Hack Nerd Font Mono, Inconsolata, Consolas"
    else "Hack Nerd Font, Inconsolata, Consolas";

local preferred_icon_theme = if apply_configs.host.is_macos
    then "vscode-icons"
    else "a-file-icon-vscode";

local preferred_product_icon_theme = if apply_configs.host.is_macos
    then "macos-modern"
    else "feather-vscode";

local editorSettings = {
    "editor.fontFamily": preferred_font_families,
    "editor.fontLigatures": true,
    "editor.fontSize": 14,
    "editor.formatOnType": true,
    "editor.renderWhitespace": "all",
    "editor.rulers": [
        120
    ],
};

local terminalSettings = {
    "terminal.external.osxExec": "iTerm.app",
    "terminal.integrated.automationProfile.osx": {
        "args": [
            "-l"
        ],
        "path": "/opt/homebrew/bin/zsh"
    },
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.defaultProfile.osx": "zsh",
    "terminal.integrated.enableImages": true,
    "terminal.integrated.fontFamily": preferred_font_families,
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

local copilotSettings = {
    "github.copilot.nextEditSuggestions.enabled": true,
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
    "js/ts.implicitProjectConfig.checkJs": true,
    "peacock.favoriteColors": [PeacockColor(c.key, c.value) for c in std.objectKeysValues(color_defs.PeacockColors)],
    "typescript.enablePromptUseWorkspaceTsdk": true,
    "window.zoomLevel": 1,
    "workbench.editor.closeOnFileDelete": true,
    "workbench.editor.tabActionLocation": if apply_configs.host.is_macos then 'left' else 'right',
    "workbench.iconTheme": preferred_icon_theme,
    "workbench.productIconTheme": preferred_product_icon_theme,
    "workbench.settings.editor": "json",
    "workbench.startupEditor": "none",
    "update.mode": "none",
}
    + editorSettings
    + terminalSettings
    + javaSettings
    + vimSettings
    + copilotSettings
