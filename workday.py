#!/usr/bin/python

import subprocess
import sys
import work_env


def main():
    hosts = work_env.workstation_infos.keys()
    try:
        subprocess.run(['gcertstatus', '--check_loas2', '--quiet'], check=True)
    except subprocess.CalledProcessError:
        print('>> gcert has expired. Invoking gcert login flow.')
        subprocess.run(['gcert'], check=True)
    for host in hosts:
        try:
            subprocess.run(['ssh', host, 'gcertstatus', '--check_loas2', '--quiet'], check=True)
        except subprocess.CalledProcessError:
            print(f'>> gcert has expired on {host}. Invoking gcert login flow.')
            # "Shared connection ... closed" gets written to stderr because of the psuedo-tty
            subprocess.run(['ssh', '-t', host, 'gcert'], check=True, stderr=subprocess.DEVNULL)

    for host in hosts:
        repo_path = work_env.workstation_infos[host]
        print(f'>> Synching repo {repo_path} for {host}.')
        subprocess.run(['ssh', host, f'cd {repo_path} && repo sync'], check=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
