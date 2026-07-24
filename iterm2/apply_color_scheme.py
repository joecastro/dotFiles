#!/usr/bin/env python3

import json
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

iterm_color_keys: list[str] = [
    'fg',
    'bg',
    'bold',
    'link',
    'selbg',
    'selfg',
    'curbg',
    'curfg',
    'underline',
    'tab',
    'black',
    'red',
    'green',
    'yellow',
    'blue',
    'magenta',
    'cyan',
    'white',
    'br_black',
    'br_red',
    'br_green',
    'br_yellow',
    'br_blue',
    'br_magenta',
    'br_cyan',
    'br_white',
]

scheme_2_iterm_colors: dict[str, str] = {
    'black': 'black',
    'blue': 'blue',
    'bright_black': 'br_black',
    'bright_blue': 'br_blue',
    'bright_cyan': 'br_cyan',
    'bright_green': 'br_green',
    'bright_magenta': 'br_magenta',
    'bright_red': 'br_red',
    'bright_white': 'br_white',
    'bright_yellow': 'br_yellow',
    'cyan': 'cyan',
    'green': 'green',
    'magenta': 'magenta',
    'red': 'red',
    'white': 'white',
    'yellow': 'yellow',
}


# https://iterm2.com/documentation-escape-codes.html
def print_command(key: str, color: str) -> None:
    """Print the iTerm2 escape code to set a color."""
    color_key = scheme_2_iterm_colors[key]
    color_value = color.replace('#', '')
    print(f'\033]1337;SetColors={color_key}={color_value}\007', end='')


def main(args: Sequence[str]) -> int:
    """Apply the requested color scheme."""
    if len(args) != 1:
        print('Usage: apply_color_scheme.py <scheme-name>')
        return 1

    config_file = Path.joinpath(Path.cwd(), 'color_schemes.jsonnet')
    if not Path.is_file(config_file):
        raise ValueError('Missing scheme file')

    result = subprocess.run(
        ['jsonnet', config_file], capture_output=True, check=True, text=True
    )
    schemes = json.loads(result.stdout)

    if args[0] == '--list':
        for scheme_name in schemes.keys():
            print(scheme_name)
        return 0

    scheme_name = args[0]
    if scheme_name not in schemes:
        print(f"Scheme '{scheme_name}' not found.")
        return 1

    scheme = schemes[scheme_name]
    for key, value in scheme.items():
        print_command(key, value)

    return 0


if __name__ == '__main__':
    sys.exit(main(args=sys.argv[1:]))
