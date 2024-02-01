local iterm_profiles = import './iterm_profiles.jsonnet';
{
    "AllowClipboardAccess": true,
    "AlternateMouseScroll": true,
    "AutoHideTmuxClientSession": false,
    "Command": "",
    "Default Arrangement Name": iterm_profiles.DefaultArrangement.Name,
    "Default Bookmark Guid": iterm_profiles.DefaultProfile.Guid,
    "DeleteProfile_SilenceUntil": 717726301.60112,
    "DeleteProfile_selection": 0,
    "EnableAPIServer": true,
    "EnableProxyIcon": false,
    "GlobalKeyMap": {
        "0x19-0x60000": {
            "Action": 39,
            "Text": ""
        },
        "0x9-0x40000": {
            "Action": 32,
            "Text": ""
        },
        "0xf700-0x300000": {
            "Action": 7,
            "Text": ""
        },
        "0xf701-0x300000": {
            "Action": 6,
            "Text": ""
        },
        "0xf702-0x300000": {
            "Action": 2,
            "Text": ""
        },
        "0xf702-0x320000": {
            "Action": 33,
            "Text": ""
        },
        "0xf703-0x300000": {
            "Action": 0,
            "Text": ""
        },
        "0xf703-0x320000": {
            "Action": 34,
            "Text": ""
        },
        "0xf729-0x100000": {
            "Action": 5,
            "Text": ""
        },
        "0xf72b-0x100000": {
            "Action": 4,
            "Text": ""
        },
        "0xf72c-0x100000": {
            "Action": 9,
            "Text": ""
        },
        "0xf72c-0x20000": {
            "Action": 9,
            "Text": ""
        },
        "0xf72d-0x100000": {
            "Action": 8,
            "Text": ""
        },
        "0xf72d-0x20000": {
            "Action": 8,
            "Text": ""
        },
        // META-F12 - Restore Cloud9 Window Arrangement
        "0xf70f-0x100000-0x6f": {
            "Action": 25,
            "Label": "",
            "Text": "Cloud 9\nCloud 9:Restore Window Arrangement",
            "Version": 1
        },
    },
    "HapticFeedbackForEsc": false,
    "HotkeyMigratedFromSingleToMulti": true,
    "New Bookmarks": iterm_profiles.Profiles,
    "OpenArrangementAtStartup": false,
    "OpenBookmark": false,
    "OpenNoWindowsAtStartup": false,
    "PerPaneBackgroundImage": false,
    "PointerActions": {
        "Button,1,1,,": {
            "Action": "kContextMenuPointerAction"
        },
        "Button,2,1,,": {
            "Action": "kPasteFromClipboardPointerAction"
        },
        "Gesture,ThreeFingerSwipeDown,,": {
            "Action": "kPrevWindowPointerAction"
        },
        "Gesture,ThreeFingerSwipeLeft,,": {
            "Action": "kPrevTabPointerAction"
        },
        "Gesture,ThreeFingerSwipeRight,,": {
            "Action": "kNextTabPointerAction"
        },
        "Gesture,ThreeFingerSwipeUp,,": {
            "Action": "kNextWindowPointerAction"
        }
    },
    "Print In Black And White": true,
    "PromptOnQuit": false,
    "QuitWhenAllWindowsClosed": false,
    "ShowPaneTitles": false,
    "SoundForEsc": false,
    "StatusBarPosition": 0,
    "TabStyleWithAutomaticOption": 4,
    "UseBorder": true,
    "VisualIndicatorForEsc": false,
    "Window Arrangements": {
          [arrangement.Name]: [arrangement]
          for arrangement in iterm_profiles.WindowArrangements
    },
    "findMode_iTerm": 0,
    "kCPKSelectionViewPreferredModeKey": 0,
    "kCPKSelectionViewShowHSBTextFieldsKey": false
}