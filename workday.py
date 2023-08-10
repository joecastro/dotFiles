#!/usr/bin/python

import sys
import work_env


def init_gcert(host):
    ops = [f'Initializing gcert (interactive) for {host}']
    ops.append(['ssh', '-t', host, 'gcertstatus --check_loas2 --quiet || gcert'])

    return ops


def sync_repo(host, repo_path):
    ops = [f'Synching repo {repo_path} for {host}']
    ops.append(['ssh', '-t', host, f'cd {repo_path} && repo sync'])

    return ops


def main():
    hosts = work_env.workstation_infos.keys()

    ops = []
    for host in hosts:
        ops.extend(init_gcert(host))

    for host in hosts:
        ops.extend(sync_repo(host, work_env.workstation_infos[host]))

    work_env.run_ops(ops)
    return 0


if __name__ == "__main__":
    sys.exit(main())
