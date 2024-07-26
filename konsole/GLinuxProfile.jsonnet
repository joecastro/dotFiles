std.manifestIni({
    sections: {
        Appearance: {
            ColorScheme: 'Tango',
            Font: 'CaskaydiaCove Nerd Font Mono,14,-1,5,50,0,0,0,0,0',
            UseFontLineChararacters: true,
        },
        'Cursor Options': {
            CursorShape: 1,
        },
        General: {
            AlternatingBackground: 1,
            DimWhenInactive: false,
            Icon: std.extVar('home') + '/.local/share/konsole/google_logo.svg',
            LocalTabTitleFormat: '%n | %d',
            Name: 'GLinux',
            Parent: 'FALLBACK/',
            StartInCurrentSessionDir: false,
        },
        Scrolling: {
            HistorySize: 10000,
        },
    },
})
