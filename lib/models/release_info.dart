class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }
}

class ReleaseInfo {
  final String tagName;
  final String version;
  final String releaseName;
  final String body;
  final bool isPrerelease;
  final DateTime publishedAt;
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.releaseName,
    required this.body,
    required this.isPrerelease,
    required this.publishedAt,
    required this.assets,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final assetsList = json['assets'] as List<dynamic>? ?? [];

    return ReleaseInfo(
      tagName: tagName,
      version: version,
      releaseName: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPrerelease: json['prerelease'] as bool? ?? false,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      assets: assetsList.map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static int _parseNum(String s) {
    final num = int.tryParse(s);
    return num ?? 0;
  }

  static int compareVersion(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final aNum = i < aParts.length ? _parseNum(aParts[i]) : 0;
      final bNum = i < bParts.length ? _parseNum(bParts[i]) : 0;
      if (aNum != bNum) return aNum - bNum;
    }
    return 0;
  }
}
