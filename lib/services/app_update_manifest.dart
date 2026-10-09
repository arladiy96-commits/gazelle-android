/// Release metadata contains no employee/account information.
class AppUpdateManifest {
  final int code;
  final String version;
  final Uri url;
  final String sha256;
  final int size;
  AppUpdateManifest(this.code, this.version, this.url, this.sha256, this.size);

  factory AppUpdateManifest.parse(Object? data, String repository) {
    if (data is! Map<String, dynamic> ||
        data['schema'] != 1 ||
        data['package'] != 'com.gazelle.gazelle_android') {
      throw const FormatException('Неверный файл обновления.');
    }
    final code = data['versionCode'];
    final version = data['versionName'];
    final size = data['size'];
    final hash = data['sha256'];
    final url = Uri.tryParse(data['apkUrl'] is String ? data['apkUrl'] : '');
    if (code is! int ||
        code < 1 ||
        code > 2100000000 ||
        version is! String ||
        version.isEmpty ||
        version.length > 80 ||
        size is! int ||
        size < 1 ||
        size > 600 * 1024 * 1024 ||
        hash is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        url.hasQuery ||
        url.hasFragment ||
        url.userInfo.isNotEmpty ||
        !url.path.startsWith('/$repository/releases/download/') ||
        !url.path.endsWith('/app-release.apk') ||
        url.pathSegments.contains('..')) {
      throw const FormatException('Неверные параметры обновления.');
    }
    return AppUpdateManifest(code, version, url, hash, size);
  }
}
