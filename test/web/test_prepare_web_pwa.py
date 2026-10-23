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
            (root / '.last_build_id').write_text('build-only metadata')
            (root / 'main.dart.js').write_text('code')
            pwa.prepare(root)
            first = (root / 'personal-player-sw.js').read_text()
            self.assertIn('./index.html', first)
            self.assertIn('./main.dart.js', first)
            self.assertNotIn('__CACHE__', first)
            self.assertNotIn('.last_build_id', first)
            pwa.prepare(root)
            self.assertEqual(first, (root / 'personal-player-sw.js').read_text())
            (root / 'main.dart.js').write_text('updated code')
            pwa.prepare(root)
            self.assertNotEqual(first, (root / 'personal-player-sw.js').read_text())

    def test_entrypoints_use_content_hashes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'index.html').write_text('<script src="flutter_bootstrap.js"></script>')
            (root / 'main.dart.js').write_text('player code')
            (root / 'flutter_bootstrap.js').write_text('load("main.dart.js")')
            pwa.prepare(root)
            self.assertFalse((root / 'main.dart.js').exists())
            self.assertFalse((root / 'flutter_bootstrap.js').exists())
            bootstrap = next(root.glob('flutter_bootstrap.*.js'))
            main = next(root.glob('main.*.dart.js'))
            self.assertIn(bootstrap.name, (root / 'index.html').read_text())
            self.assertIn(main.name, bootstrap.read_text())
            first = (root / 'personal-player-sw.js').read_text()
            pwa.prepare(root)
            self.assertEqual(first, (root / 'personal-player-sw.js').read_text())

    def test_manifest_assets_exist_with_exact_case(self):
        manifest = json.loads((ROOT / 'web/manifest.json').read_text())
        self.assertEqual(manifest['display'], 'standalone')
        self.assertEqual(manifest['scope'], './')
        for icon in manifest['icons']:
            self.assertTrue((ROOT / 'web' / icon['src']).is_file())


if __name__ == '__main__':
    unittest.main()
