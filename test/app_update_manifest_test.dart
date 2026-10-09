import '../lib/services/app_update_manifest.dart';

void main() {
  final valid = <String, dynamic>{
    'schema': 1,
    'package': 'com.gazelle.gazelle_android',
    'versionCode': 214000001,
    'versionName': '1.1.0',
    'size': 50000000,
    'sha256': 'a' * 64,
    'apkUrl': 'https://github.com/owner/repo/releases/download/android-214000001/app-release.apk',
  };
  final parsed = AppUpdateManifest.parse(valid, 'owner/repo');
  if (parsed.code != 214000001 || parsed.size != 50000000)
    throw StateError('valid release rejected');
  void rejects(String field, Object? value) {
    try {
      AppUpdateManifest.parse({...valid, field: value}, 'owner/repo');
    } on FormatException {
      return;
    }
    throw StateError('accepted invalid $field=$value');
  }

  rejects('schema', 2);
  rejects('package', 'other.app');
  rejects('versionCode', '214000001');
  rejects('versionCode', 0);
  rejects('versionCode', 2100000001);
  rejects('size', -1);
  rejects('size', 700 * 1024 * 1024);
  rejects('sha256', 'abc');
  rejects(
    'apkUrl',
    'http://github.com/owner/repo/releases/download/tag/app-release.apk',
  );
  rejects(
    'apkUrl',
    'https://github.com/attacker/repo/releases/download/tag/app-release.apk',
  );
  rejects(
    'apkUrl',
    'https://github.com.example.com/owner/repo/releases/download/tag/app-release.apk',
  );
  rejects(
    'apkUrl',
    'https://github.com/owner/repo/releases/download/tag/app-release.apk?x=y',
  );
  print(
    'PASS: valid metadata; corrupt, oversized, wrong-package and untrusted-source metadata rejected.',
  );
}
