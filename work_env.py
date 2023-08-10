#!/usr/bin/python

import os
import subprocess

workstation_infos = {
    'joec1.c.googlers.com': 'main',
    'joec2.c.googlers.com': 'udc_dev',
    'joec3.c.googlers.com': 'main'
}

known_hosts = workstation_infos.keys()

SYS_COMMAND_PREFIX = 'sys_command: '


def make_sys_op(command):
    return SYS_COMMAND_PREFIX + command


def print_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(SYS_COMMAND_PREFIX):
                print(f'DEBUG SYSCALL: {entry}')
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(SYS_COMMAND_PREFIX):
                os.system(entry.removeprefix(SYS_COMMAND_PREFIX))
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            subprocess.run(entry, check=False)
        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')
