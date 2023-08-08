#!/usr/bin/python

import os
import subprocess

workstation_infos = {
    'joec1.c.googlers.com': 'main',
    'joec2.c.googlers.com': 'udc_dev',
    'joec3.c.googlers.com': 'main'
}

known_hosts = workstation_infos.keys()

sys_command_prefix = 'sys_command: '


def print_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(sys_command_prefix):
                print(f'DEBUG SYSCALL: {entry}')
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise 'bad'


def run_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(sys_command_prefix):
                os.system(entry.removeprefix(sys_command_prefix))
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            subprocess.run(entry)
        elif callable(entry):
            entry()
        else:
            raise 'bad'
