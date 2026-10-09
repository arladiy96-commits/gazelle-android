#!/usr/bin/env python3
"""CI-only atomic publication: draft release -> two assets -> published latest."""
import hashlib
import json
import os
from pathlib import Path
import subprocess


def gh(*args):
    return subprocess.run(['gh', *args], check=True, text=True, capture_output=True).stdout


def main():
    repo = os.environ['GITHUB_REPOSITORY']
    sha = os.environ['GITHUB_SHA']
    head = gh('api', f'repos/{repo}/git/ref/heads/main', '--jq', '.object.sha').strip()
    if head != sha:
        print('В main уже есть более новый коммит: этот APK не публикуется.')
        return
    code = int(os.environ['UPDATE_CODE'])
    version = os.environ['UPDATE_VERSION']
    tag = f'android-{code}'
    apk = Path('build/app/outputs/flutter-apk/app-release.apk')
    if not apk.is_file() or not apk.stat().st_size:
        raise SystemExit('APK отсутствует')
    metadata = {'schema': 1, 'package': 'com.gazelle.gazelle_android',
        'versionCode': code, 'versionName': version,
        'apkUrl': f'https://github.com/{repo}/releases/download/{tag}/app-release.apk',
        'sha256': hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(), 'size': apk.stat().st_size}
    manifest = Path(os.environ['RUNNER_TEMP']) / 'update.json'
    manifest.write_text(json.dumps(metadata, ensure_ascii=False, indent=2))
    notes = Path(os.environ['RUNNER_TEMP']) / 'release-notes.md'
    notes.write_text(f'Мельница {version}, сборка {code}.\n\nКоммит main: {sha}.\n\n'
        'Устанавливайте APK поверх предыдущей версии с постоянной подписью.\n')
    gh('release', 'create', tag, str(apk), str(manifest), '--repo', repo,
        '--target', sha, '--draft', '--title', f'Мельница {version} ({code})', '--notes-file', str(notes))
    # Check again after asset upload. Never make an obsolete build latest.
    if gh('api', f'repos/{repo}/git/ref/heads/main', '--jq', '.object.sha').strip() != sha:
        print('Новая версия main появилась во время загрузки: релиз оставлен черновиком.')
        return
    gh('release', 'edit', tag, '--repo', repo, '--draft=false', '--latest')
    print('Опубликован '+tag)


if __name__ == '__main__':
    main()
