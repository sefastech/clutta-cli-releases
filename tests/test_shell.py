import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class ShellInstaller(unittest.TestCase):
    def test_failure_boundaries(self):
        installer = Path(__file__).resolve().parents[1] / "install.sh"
        for mode in ("stable", "rc-override", "metadata", "prerelease", "malformed",
                     "download", "mismatch", "duplicate", "wrong-asset",
                     "invalid-version", "newline-version"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                tools, target = root / "tools", root / "target"
                tools.mkdir()
                target.mkdir()
                binary = target / "clutta"
                binary.write_text("previous installation")
                fixture = "#!/bin/sh\nprintf 'fixture clutta\\n'\n"
                # Mock only transport, retaining the real shell installer,
                # checksum tools, filesystem and exit status.
                curl = tools / "curl"
                curl.write_text("""#!/usr/bin/env python3
import hashlib, os, sys
from pathlib import Path
args = sys.argv[1:]
url = next(a for a in args if a.startswith('https://'))
mode = os.environ['TEST_MODE']
fixture = "#!/bin/sh\\nprintf 'fixture clutta\\\\n'\\n"
if '/api.github.com/' in url:
    assert url.endswith('/releases/latest'), url
    if mode == 'metadata': sys.exit(22)
    tag = 'v1.2.4-rc1' if mode == 'prerelease' else ('bad' if mode == 'malformed' else 'v1.2.3')
    print('{"tag_name": "' + tag + '", "draft": false, "prerelease": false}')
else:
    if mode == 'download': sys.exit(22)
    if mode == 'rc-override': assert '/v1.2.4-rc1/' in url
    output = Path(args[args.index('-o') + 1])
    if url.endswith('sha256sums.txt'):
        digest = hashlib.sha256(fixture.encode()).hexdigest()
        if mode == 'mismatch': digest = '0' * 64
        text = digest + '  clutta-linux-amd64'
        if mode == 'wrong-asset': text += '.backup'
        if mode == 'duplicate': text += '\\n' + text
        output.write_text(text + '\\n')
    else:
        output.write_text(fixture)
""")
                curl.chmod(0o755)
                uname = tools / "uname"
                uname.write_text("#!/bin/sh\ncase \"$1\" in -s) echo Linux;; -m) echo x86_64;; esac\n")
                uname.chmod(0o755)
                version = {"rc-override": "v1.2.4-rc1", "invalid-version": "../../bad",
                           "newline-version": "v1.2.3\nbad"}.get(mode, "")
                env = dict(os.environ, PATH=f"{tools}:{os.environ['PATH']}",
                           CLUTTA_INSTALL_DIR=str(target), CLUTTA_VERSION=version,
                           TEST_MODE=mode)
                result = subprocess.run(["sh", str(installer)], env=env,
                                        capture_output=True, text=True, timeout=20)
                success = mode in ("stable", "rc-override")
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
                self.assertEqual(binary.read_text(), fixture if success else "previous installation")


if __name__ == "__main__":
    unittest.main()
