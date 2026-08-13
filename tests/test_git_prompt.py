from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class GitPromptTests(unittest.TestCase):
    test_root: Path
    remote: Path
    seed: Path
    checkout: Path

    def setUp(self) -> None:
        self.test_root = Path(tempfile.mkdtemp(prefix='dotfiles-git-prompt.'))
        self.remote = self.test_root / 'fork.git'
        self.seed = self.test_root / 'seed'
        self.checkout = self.test_root / 'checkout'

        self.git('init', '--bare', str(self.remote))
        self.git('init', '-b', 'main', str(self.seed))
        self.git('-C', str(self.seed), '-c', 'user.name=Test', '-c',
                 'user.email=test@example.invalid', 'commit', '--allow-empty',
                 '-m', 'initial')
        self.git('-C', str(self.seed), 'remote', 'add', 'fork', str(self.remote))
        self.git('-C', str(self.seed), 'push', '-u', 'fork', 'main')
        self.git('--git-dir', str(self.remote), 'symbolic-ref', 'HEAD',
                 'refs/heads/main')
        self.git('clone', str(self.remote), str(self.checkout))
        self.git('-C', str(self.checkout), 'remote', 'rename', 'origin', 'fork')

    def tearDown(self) -> None:
        shutil.rmtree(self.test_root)

    @staticmethod
    def git(*args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ['git', *args], check=True, capture_output=True, text=True
        )

    def add_remote_commit(self) -> None:
        self.git('-C', str(self.seed), '-c', 'user.name=Test', '-c',
                 'user.email=test@example.invalid', 'commit', '--allow-empty',
                 '-m', 'remote change')
        self.git('-C', str(self.seed), 'push', 'fork', 'main')

    def compare(self, *, disable_fetch: bool = False) -> int:
        git_funcs = Path(__file__).parents[1] / 'shell' / 'git_funcs.sh'
        script = f'''
            source {git_funcs!s}
            _dotTrace_enter() {{ :; }}
            _dotTrace() {{ :; }}
            _dotTrace_exit() {{ return "${{1:-0}}"; }}
            __time_delta() {{ awk "BEGIN {{ print $(date +%s) - $1 }}"; }}
            __git_compare_upstream_changes
            printf '%s' "$?"
        '''
        environment = os.environ.copy()
        if disable_fetch:
            environment['DISABLE_GIT_STATUS_FETCH'] = '1'
        result = subprocess.run(
            ['/bin/bash', '-c', script], cwd=self.checkout, env=environment,
            check=True, capture_output=True, text=True
        )
        return int(result.stdout)

    def test_fetches_tracking_remote_and_reports_behind(self) -> None:
        self.add_remote_commit()

        self.assertEqual(self.compare(), 4)
        marker = self.checkout / '.git' / 'cute-prompt-fetch' / 'fork'
        self.assertTrue(marker.is_file())

    def test_disable_fetch_uses_cached_tracking_ref(self) -> None:
        self.add_remote_commit()

        self.assertEqual(self.compare(disable_fetch=True), 0)


if __name__ == '__main__':
    unittest.main()
