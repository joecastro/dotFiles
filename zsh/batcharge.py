#! /usr/bin/env python3

import math
import subprocess

color_codes = {
    'black': '\033[0;30m',
    'dark_gray': '\033[01;30m',
    'red': '\033[0;31m',
    'bright_red':'\033[01;31m',
    'green': '\033[0;32m',
    'bright_green': '\033[01;32m',
    'brown=':'\033[0;33m',
    'yellow': '\033[1;33m',
    'blue': '\033[0;34m',
    'bright_blue': '\033[1;34m',
    'purple': '\033[0;35m',
    'light_purple': '\033[1;35m',
    'cyan': '\033[0;36m',
    'bright_cyan': '\033[1;36m',
    'light_gray': '\033[0;37m',
    'white': '\033[1;37m',
    'reset': '\033[0m'
}


def escape_color(color):
    return f'%{{{color_codes[color]}%}}'


if __name__ == "__main__":
    SLOT_COUNT = 10
    EMPTY_ICON = '_'
    FULL_ICON = '#'

    p = subprocess.Popen(["ioreg", "-rc", "AppleSmartBattery"], stdout=subprocess.PIPE)
    output = [raw_line.decode('utf-8').strip() for raw_line in p.communicate()[0].splitlines()]

    # This thing outputs structured but inconsistent json-like content. These fields are simple "key"=value
    def parse_float(property_name):
        candidate_line = [line for line in output if line.startswith(property_name)][0]
        return float(candidate_line.rpartition('=')[-1].strip())

    battery_current = parse_float('"CurrentCapacity"')
    battery_max = parse_float('"MaxCapacity"')
    battery_charge_percent = int((battery_current / battery_max) * 100)

    fill_count = math.floor(battery_charge_percent / SLOT_COUNT)
    empty_count = SLOT_COUNT - fill_count

    print(escape_color('green') + (FULL_ICON * fill_count) + escape_color('red') + (EMPTY_ICON * empty_count) + escape_color('reset'))
