"""Check target configuration and guard placement without an iOS SDK."""
import pathlib
import plistlib

root = pathlib.Path(__file__).resolve().parents[1]
with (root / 'MinisThinkingRules.plist').open('rb') as handle:
    assert plistlib.load(handle) == {'Filter': {'Bundles': ['com.openminis.app']}}
assert ':16.0\n' in (root / 'Makefile').read_text()
assert 'firmware (>= 16.0)' in (root / 'control').read_text()
source = (root / 'Tweak.m').read_text().split('__attribute__((constructor))', 1)[1]
guards = source.split('MTREntry *entry', 1)[0]
assert guards.count('return;') == 4
assert 'if (@available(iOS 16.0, *))' in guards
assert 'if (![bundle.bundleIdentifier isEqualToString:@"com.openminis.app"]) return;' in guards
assert 'if (![@"1.15" isEqual:[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]) return;' in guards
assert 'if (![@"16" isEqual:[bundle objectForInfoDictionaryKey:@"CFBundleVersion"]]) return;' in guards
assert 'com.aztut.app' not in source
print('OpenMinis 1.15 build 16 target checks passed')
