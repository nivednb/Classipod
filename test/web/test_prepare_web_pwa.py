import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('pwa', ROOT / 'scripts/prepare_web_pwa.py')
pwa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pwa)


class PwaTests(unittest.TestCase):
    def test_shell_is_versioned_and_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'index.html').write_text('player')
            (root / 'main.dart.js').write_text('code')
            pwa.prepare(root)
            first = (root / 'personal-player-sw.js').read_text()
            self.assertIn('./index.html', first)
            self.assertIn('./main.dart.js', first)
            self.assertNotIn('__CACHE__', first)
            pwa.prepare(root)
            self.assertEqual(first, (root / 'personal-player-sw.js').read_text())
            (root / 'main.dart.js').write_text('updated code')
            pwa.prepare(root)
            self.assertNotEqual(first, (root / 'personal-player-sw.js').read_text())

    def test_manifest_assets_exist_with_exact_case(self):
        manifest = json.loads((ROOT / 'web/manifest.json').read_text())
        self.assertEqual(manifest['display'], 'standalone')
        self.assertEqual(manifest['scope'], './')
        for icon in manifest['icons']:
            self.assertTrue((ROOT / 'web' / icon['src']).is_file())


if __name__ == '__main__':
    unittest.main()
