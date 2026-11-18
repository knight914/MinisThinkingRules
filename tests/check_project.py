#!/usr/bin/env python3
import json
import pathlib
import plistlib
import sys

import yaml

root = pathlib.Path(__file__).resolve().parents[1]
with (root / 'MinisThinkingRules.plist').open('rb') as handle:
    assert plistlib.load(handle) == {'Filter': {'Bundles': ['com.openminis.app']}}
control = dict(line.split(': ', 1) for line in (root / 'control').read_text().splitlines())
assert control['Package'] == 'com.knight914.ministhinkingrules'
assert control['Name'] == 'MinisThinkingRules'
assert control['Architecture'] == 'iphoneos-arm64e'
assert 'THEOS_PACKAGE_ARCH = iphoneos-arm64e' in (root / 'Makefile').read_text()
assert 'THEOS_PACKAGE_ARCH = iphoneos-arm64' in (root / 'Makefile').read_text()
workflow = yaml.safe_load((root / '.github/workflows/build.yml').read_text())
assert workflow['on'] == {'push': {'branches': ['work/**']}}
assert workflow['permissions'] == {'contents': 'read'}
job = workflow['jobs']['package']
assert job['runs-on'] == 'macos-15'
assert [(item['scheme'], item['repo'], item['architecture']) for item in job['strategy']['matrix']['include']] == [
    ('rootless', 'https://github.com/theos/theos', 'iphoneos-arm64'),
    ('roothide', 'https://github.com/roothide/theos', 'iphoneos-arm64e'),
]
for file in root.rglob('*'):
    is_source = file.name in {'Makefile', 'control'} or file.suffix in {'.m', '.h', '.py', '.md', '.plist', '.yml'}
    if is_source and file.is_file() and not set(file.relative_to(root).parts) & {'.git', '.theos', 'packages', '__pycache__'}:
        data = file.read_text()
        assert data.endswith('\n') and all(s == s.rstrip() for s in data.splitlines()), file
print('Project metadata, YAML, and whitespace checks passed')
if '--live' in sys.argv:
    wrapper = json.load(sys.stdin)
    assert wrapper['ok'] is True and isinstance(wrapper['value'], str)
    providers = json.loads(wrapper['value'])
    assert isinstance(providers, list)
    for provider in providers:
        assert isinstance(provider['provider'], str) and isinstance(provider['provider_id'], str)
        for key in ('custom', 'builtin'):
            assert isinstance(provider[key], list)
            for rule in provider[key]:
                assert isinstance(rule['label'], str) and isinstance(rule['scope'], str)
    print(f'Live read-only CLI schema passed ({len(providers)} provider entries; no payload logged)')
