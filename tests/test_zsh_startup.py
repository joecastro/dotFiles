from __future__ import annotations

import os
import platform
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class ZshStartupTests(unittest.TestCase):
    home: Path
    test_root: Path
    outside_dir: Path
    repo_dir: Path
    nvm_version: str

    @classmethod
    def setUpClass(cls) -> None:
        if shutil.which('zsh') is None:
            raise unittest.SkipTest('zsh is not installed')

        cls.home = Path(os.environ.get('DOTFILES_TEST_HOME', Path.home()))
        versions_dir = cls.home / '.nvm' / 'versions' / 'node'
        versions = sorted(
            versions_dir.glob('v*'), key=lambda path: path.stat().st_mtime, reverse=True
        )
        if not versions:
            raise unittest.SkipTest(f'no NVM Node versions found under {versions_dir}')

        cls.nvm_version = os.environ.get(
            'ZSH_STARTUP_TEST_NVM_VERSION', versions[0].name.removeprefix('v')
        )
        cls.test_root = Path(tempfile.mkdtemp(prefix='dotfiles-zsh-startup.'))
        cls.outside_dir = cls.test_root / 'outside'
        cls.repo_dir = cls.test_root / 'repo'
        cls.outside_dir.mkdir()
        (cls.repo_dir / '.git' / 'hooks').mkdir(parents=True)
        (cls.repo_dir / '.nvmrc').write_text(f'{cls.nvm_version}\n', encoding='utf-8')

        hook_tool = cls.repo_dir / 'hook-tool'
        hook_tool.write_text(
            '#!/usr/bin/env node\nconsole.log(`hook-node=${process.version}`)\n',
            encoding='utf-8',
        )
        hook_tool.chmod(0o755)

        pre_push = cls.repo_dir / '.git' / 'hooks' / 'pre-push'
        pre_push.write_text(
            '#!/bin/sh\nset -eu\n./hook-tool\npnpm --version >/dev/null\n',
            encoding='utf-8',
        )
        pre_push.chmod(0o755)

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, 'test_root'):
            shutil.rmtree(cls.test_root)

    @classmethod
    def run_zsh(
        cls, mode: str, directory: Path, command: str
    ) -> subprocess.CompletedProcess[str]:
        environment = {
            'HOME': str(cls.home),
            'HOMEBREW_NO_ANALYTICS': '1',
            'HOMEBREW_NO_AUTO_UPDATE': '1',
            'LOGNAME': os.environ.get('LOGNAME', os.environ.get('USER', '')),
            'NVM_DIR': str(cls.home / '.nvm'),
            'PATH': '/usr/bin:/bin:/usr/sbin:/sbin',
            'TERM': os.environ.get('TERM', 'xterm-256color'),
            'USER': os.environ.get('USER', ''),
        }
        return subprocess.run(
            ['/bin/zsh', f'-{mode}', command],
            cwd=directory,
            env=environment,
            check=True,
            capture_output=True,
            text=True,
        )

    @classmethod
    def tool_report(cls, mode: str, directory: Path) -> dict[str, str]:
        command = r"""
            for tool in brew node pnpm uv python3 java; do
                command -v "${tool}" >/dev/null || exit 10
                printf "RESULT %s=%s\n" "${tool}" "$(command -v "${tool}")"
            done
            printf "RESULT node-version=%s\n" "$(node --version)"
            printf "RESULT pnpm-version=%s\n" "$(pnpm --version)"
            printf "RESULT uv-version=%s\n" "$(uv --version)"
            printf "RESULT python-version=%s\n" "$(python3 --version)"
            printf "RESULT java-home=%s\n" "${JAVA_HOME:-}"
            duplicates=$(printf "%s" "${PATH}" | tr ":" "\n" | sort | uniq -d)
            [[ -z "${duplicates}" ]] || exit 11
        """
        result = cls.run_zsh(mode, directory, command)
        return dict(
            line.removeprefix('RESULT ').split('=', maxsplit=1)
            for line in result.stdout.splitlines()
            if line.startswith('RESULT ')
        )

    def test_login_shells_have_matching_tools_outside_repository(self) -> None:
        self.assertEqual(
            self.tool_report('lc', self.outside_dir),
            self.tool_report('lic', self.outside_dir),
        )

    def test_login_shells_select_repository_nvmrc(self) -> None:
        expected_version = f'v{self.nvm_version}'
        noninteractive = self.tool_report('lc', self.repo_dir)
        interactive = self.tool_report('lic', self.repo_dir)

        self.assertEqual(noninteractive, interactive)
        self.assertEqual(noninteractive['node-version'], expected_version)
        if platform.system() == 'Darwin':
            self.assertTrue(noninteractive['java-home'].startswith('/'))

    def test_pre_push_hook_has_node_and_pnpm_noninteractively(self) -> None:
        result = self.run_zsh(
            'lc', self.repo_dir, './.git/hooks/pre-push origin example.invalid'
        )
        self.assertIn(f'hook-node=v{self.nvm_version}', result.stdout)

    def test_pre_push_hook_has_node_and_pnpm_interactively(self) -> None:
        result = self.run_zsh(
            'lic', self.repo_dir, './.git/hooks/pre-push origin example.invalid'
        )
        self.assertIn(f'hook-node=v{self.nvm_version}', result.stdout)


if __name__ == '__main__':
    unittest.main()
