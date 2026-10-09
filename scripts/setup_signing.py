#!/usr/bin/env python3
"""Run ONCE yourself in a trusted, gh-authenticated terminal in the repository."""
import base64
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess


def gh(*args, input=None):
    return subprocess.run(['gh', *args], input=input, text=True, check=True, capture_output=True).stdout


def main():
    if not shutil.which('keytool') or not shutil.which('gh'):
        raise SystemExit('Нужны Java (keytool) и GitHub CLI (gh). В Codespaces установите Java, затем повторите.')
    repo = gh('repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner').strip()
    names = {'ANDROID_KEYSTORE_BASE64', 'ANDROID_STORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD'}
    existing = {item['name'] for item in json.loads(gh('secret', 'list', '--repo', repo, '--json', 'name'))}
    if existing & names:
        raise SystemExit('Секреты подписи уже существуют. Скрипт их не заменяет. Используйте существующий ключ.')
    folder = Path.home() / '.melnitsa-signing' / repo.replace('/', '_')
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    folder.chmod(0o700)
    key = folder / 'release.jks'
    credentials = folder / 'signing-credentials.json'
    if key.exists() or credentials.exists():
        raise SystemExit('Локальный ключ уже создан: '+str(folder)+'. Не создавайте новый. При неполной настройке загрузите сохранённые значения в GitHub Secrets.')
    password = secrets.token_urlsafe(32)
    alias = 'melnitsa'
    env = dict(os.environ, MELNITSA_SETUP_PASSWORD=password)
    subprocess.run(['keytool', '-genkeypair', '-noprompt', '-keystore', str(key),
        '-storetype', 'JKS', '-alias', alias, '-keyalg', 'RSA', '-keysize', '3072',
        '-validity', '10000', '-dname', 'CN=Melnitsa, O=Melnitsa',
        '-storepass:env', 'MELNITSA_SETUP_PASSWORD', '-keypass:env', 'MELNITSA_SETUP_PASSWORD'],
        env=env, check=True, capture_output=True)
    key.chmod(0o600)
    values = {'ANDROID_KEYSTORE_BASE64': base64.b64encode(key.read_bytes()).decode(),
        'ANDROID_STORE_PASSWORD': password, 'ANDROID_KEY_ALIAS': alias, 'ANDROID_KEY_PASSWORD': password}
    fd = os.open(credentials, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as out:
        json.dump(values, out, indent=2)
    for name, value in values.items():
        gh('secret', 'set', name, '--repo', repo, input=value)
    print('Готово. Четыре секрета подписи установлены для '+repo)
    print('Сохраните себе оба файла из '+str(folder))
    print('Не публикуйте их и не добавляйте в git. Не меняйте ключ для следующих обновлений.')


if __name__ == '__main__':
    main()
